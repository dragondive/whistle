#!/bin/bash

display_help()
{
cat << EOF
Usage: whistle.bash [OPTION]...

-h, --help
    Display this help message and exit

-u, --username <username>
    Create a local user <username> in the WSL2 instance and set it as the default user.
    Also prompts to set the password for the user.

    If not specified, the WSL2 distro name will be the default username and password.

-b, --setup-bundles [bundles,...]
    Comma-separated list of setup bundles to be executed. Some setup bundles are
    considered core bundles and will always be executed.

    Usually the setup bundles will install the respective application, some useful
    utilities, and perform standard configurations. Additional information about
    specific setup bundles is described below.

Available setup bundles:
    - rust
    - python3
    - copy-ssh-keys
        Copies ssh keys from Windows to WSL2 and sets the correct permissions.
    - docker [core bundle]
    - git [core bundle]
    - utils [core bundle]

EOF
}

ARGUMENTS=("$@")
options=$(getopt -l \
    "help,username:,setup-bundles:", \
    -o "h,u:,b:" -- \
    "${ARGUMENTS[@]}")
eval set -- "$options"

declare -A EXECUTE_BUNDLE
EXECUTE_BUNDLE=(
    [python3]=0
    [rust]=0
    [copy-ssh-keys]=0
    [docker]=1
    [git]=1
    [utils]=1
)

while true; do
    case "$1" in
    -h|--help)
        display_help
        exit 0
        ;;
    -u|--username)
        shift
        export DEFAULT_USER="$1"
        ;;
    -b|--setup-bundles)
        shift
        IFS=',' read -ra BUNDLES <<< "$1"
        for BUNDLE in "${BUNDLES[@]}"; do
            EXECUTE_BUNDLE["$BUNDLE"]=1
        done
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Invalid option: $1"
        display_help
        exit 1
        ;;
    esac
shift
done

EXECUTE_BUNDLE_MESSAGE="Executing setup bundles: "
for bundle in "${!EXECUTE_BUNDLE[@]}"; do
    if [[ ${EXECUTE_BUNDLE["$bundle"]} -eq 1 ]]; then
        EXECUTE_BUNDLE_MESSAGE+="$bundle "
    fi
done
echo "$EXECUTE_BUNDLE_MESSAGE"

VSCODE_EXTENSIONS=(\
    "ms-vscode-remote.remote-containers" \
    "ms-vscode-remote.remote-ssh" \
    "ms-vscode-remote.remote-ssh-edit" \
    "ms-vscode-remote.remote-wsl" \
    "ms-vscode.remote-explorer" \
    "ms-vscode-remote.remote-wsl" \
    "ms-vscode-remote.vscode-remote-extensionpack" \
    "vscode-icons-team.vscode-icons" \
    "shd101wyy.markdown-preview-enhanced" \
    "redhat.vscode-yaml" \
    "tamasfe.even-better-toml" \
    "bierner.emojisense" \
)

if [[ $EUID -eq 0 ]]; then
    echo "Executing setup as the root user..."

    echo "Creating a new default standard user..."
    if [[ -z "$DEFAULT_USER" ]]; then
        DEFAULT_USER=$WSL_DISTRO_NAME
        DEFAULT_USER_PASSWORD=$WSL_DISTRO_NAME
        printf "%b" "No username specified. Using the WSL2 distro name "\
        "'$DEFAULT_USER' as the default username and password.\n"
    fi

    if [[ -z "$DEFAULT_USER_PASSWORD" ]]; then
        read -esp \
            "Enter password for user '$DEFAULT_USER': " DEFAULT_USER_PASSWORD
    fi
    ENCRYPTED_PASSWORD=$(echo $DEFAULT_USER_PASSWORD | openssl passwd -1 -stdin)

    useradd \
        --create-home \
        --shell /bin/bash \
        --user-group --groups adm,sudo \
        --password "$ENCRYPTED_PASSWORD" \
        $DEFAULT_USER

    ### Set the default user and enable systemd ###
    printf "%b" \
    "[user]\n" \
    "default=$DEFAULT_USER\n" \
    "[boot]\n" \
    "systemd=true\n" \
        | tee /etc/wsl.conf

    # Fix the exec format error to enable running Windows applications from WSL2.
    # credit: https://github.com/microsoft/WSL/issues/8952#issuecomment-1568212651
    sh -c 'echo :WSLInterop:M::MZ::/init:PF > /usr/lib/binfmt.d/WSLInterop.conf'
    systemctl restart systemd-binfmt

    if [[ ${EXECUTE_BUNDLE[docker]} -eq 1 ]]; then
        echo "Installing docker..."

        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker \
                   containerd runc;
        do
            sudo apt-get remove -yq $pkg 2> /dev/null
        done

        apt-get update -yq
        apt-get install -yq ca-certificates curl gnupg
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
            | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
            | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update -yq
        apt-get install -yq docker-ce docker-ce-cli containerd.io \
                            docker-buildx-plugin docker-compose-plugin

        usermod -aG docker $DEFAULT_USER # enables the user to run docker without sudo.

        VSCODE_EXTENSIONS+=(\
            "ms-azuretools.vscode-docker" \
        )
    fi

    if [[ ${EXECUTE_BUNDLE[git]} -eq 1 ]]; then
        echo "Installing git..."
        sudo apt-get install -yq git-all gitg hub kdiff3

        VSCODE_EXTENSIONS+=(\
            "eamodio.gitlens" \
            "github.vscode-pull-request-github" \
            "github.remotehub" \
            "github.vscode-github-actions" \
            "github.codespaces" \
        )
    fi

    if [[ ${EXECUTE_BUNDLE[utils]} -eq 1 ]]; then
        echo "Installing useful utilities..."
        sudo apt-get install -yq neovim-qt terminator pandoc
    fi

    if [[ ${EXECUTE_BUNDLE[python3]} -eq 1 ]]; then
        echo "Installing Python 3..."
        sudo apt-get install -yq python3 python3-pip python3-venv python3-wheel

        POETRY_HOME=/home/$DEFAULT_USER/.local
        curl -sSL https://install.python-poetry.org | POETRY_HOME=$POETRY_HOME python3 -
        printf "%b" \
        "export PATH=\"\$PATH:$POETRY_HOME\"\n" \
            | tee -a /home/$DEFAULT_USER/.profile

        VSCODE_EXTENSIONS+=(\
            "ms-python.python" \
            "ms-python.debugpy" \
            "ms-python.isort" \
        )
    fi


    if [[ ${EXECUTE_BUNDLE[rust]} -eq 1 ]]; then
        echo "Installing Rust..."
        sudo apt-get install -yq build-essential

        VSCODE_EXTENSIONS+=(\
            "rust-lang.rust-analyzer" \
            "tamasfe.even-better-toml" \
            "fill-labs.dependi" \
            "vadimcn.vscode-lldb" \
            "usernamehw.errorlens" \
            "bierner.docs-view" \
        )
    fi

    export VSCODE_EXTENSIONS_INSTALL_COMMAND="code --force --verbose "
    for extension in "${VSCODE_EXTENSIONS[@]}"; do
        VSCODE_EXTENSIONS_INSTALL_COMMAND+="--install-extension ${extension} "
    done

    echo "Switching to the standard user for further configuration..."
    exec sudo \
        --preserve-env=USERNAME,PATH,WSL_DISTRO_NAME,VSCODE_EXTENSIONS_INSTALL_COMMAND \
        --login \
        --user "$DEFAULT_USER" \
        "$(realpath $0)" "${ARGUMENTS[@]}"
fi

echo "Running configuration as the standard user..."

if [[ ${EXECUTE_BUNDLE[copy-ssh-keys]} -eq 1 ]]; then
    echo "Copying ssh keys from Windows to WSL2..."
    mkdir -p ~/.ssh && cp -v /mnt/c/Users/$USERNAME/.ssh/id_* ~/.ssh
    find ~/.ssh -type f -exec grep -rlE -- '-----BEGIN.*PRIVATE KEY-----' {} + \
        | xargs -I {} chmod -v 600 {} # private key files need to have permission 600
fi

if [[ ${EXECUTE_BUNDLE[rust]} -eq 1 ]]; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

echo "Installing vscode extensions..."
eval "$VSCODE_EXTENSIONS_INSTALL_COMMAND"

echo "WSL2 setup completed!"
echo \
"You may now start using your WSL2 instance with the following command:

    wsl -d $WSL_DISTRO_NAME
"

exit 0
