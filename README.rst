Whistle
=======

``whistle`` is a utility to automatically download Ubuntu WSL images, create new WSL2
instances and provision them.

.. contents:: **Outline**

How to use
----------

1. Download this repository as a zip file and extract it into any directory on your
   local machine.

2. Open a powershell terminal and navigate to that directory.

.. pull-quote:: \:one: **ONE-TIME SETUP**

   Install WSL with the following command, then restart your computer.

   .. code-block:: terminal

      wsl --install --no-distribution

3. Run the following command:

   .. code-block:: powershell

      PowerShell -ExecutionPolicy Bypass -File .\whistle.ps1 --WslDistroName whistleblower

   This creates a new WSL2 instance of the default Linux flavour and release with only
   the core setup bundles installed. See the `Parameters`_ section below to install
   additional optional bundles and for other customizations.

   .. pull-quote:: \:bangbang: **IMPORTANT**

      The script also creates a standard user on the WSL2 instance. By default, the
      username and password are the same as the instance name.

   .. pull-quote:: \:bulb: **TIP**

      To create another instance, run the command again with a different instance name.

   .. pull-quote:: \:drum: **ATTENTION**

      PowerShell's `execution policy <https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies>`_
      prevents execution of unsigned scripts. The ``-ExecutionPolicy Bypass`` in the
      above command bypasses it to enable ``whistle.ps1`` to be executed. I do not
      currently want to buy a code-signing certificate. However, I will easily change
      my mind if I receive enough sponsorship. See the `Sponsoring`_ section for
      sponsoring information.

Parameters
----------

.. list-table:: Parameters
   :header-rows: 1

   * - **⠀⠀⠀Parameter⠀⠀⠀**
     - **Description**
     - **Examples**
     - **Default**
     - **Notes**
   * - ``-WslDistroName``
     - Name for your new WSL2 instance.
     - ``whistleblower``, ``heavens-arena``
     - ``whistleblower``
     -
   * - ``-ReleaseName``
     - Ubuntu release name.
     - ``noble``, ``jammy``
     - ``noble``
     - Available releases at https://cloud-images.ubuntu.com/wsl/.
   * - ``-ReleaseTag``
     - Release tag of the WSL2 image to download.
     - ``current``, ``20241008``
     - ``current``
     - Available tags inside the chosen release directory at the above page.
   * - ``-ReleaseArch``
     - Architecture of the WSL2 image.
     - ``amd64``, ``arm64``
     - ``amd64``
     -
   * - ``-SetupArgs``
     - Arguments for the setup script ``whistle.bash``.
     - ``"'-h'"``, ``"'-b python3'"``, ``"'-u dragondive -b copy-ssh-keys'"``
     - ``""``
     - This needs to be enclosed in *both* double quotes and single quotes.
       Run with ``"'-h'"`` for the full description of the supported arguments.

Contributor Documentation
-------------------------

``whistle`` consists of two scripts:

1. The powershell script ``whistle.ps1`` that downloads the WSL2 image and creates an
   instance of it.
2. The bash script ``whistle.bash`` that provisions the installed WSL2 instance.

These scripts are further described in the below sections.

powershell script ``whistle.ps1``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This script performs the following main operations:

1. Download the user-specified WSL2 image: As an optimization, the images are cached to
   a standard location which avoids redownloading when the script is run multiple times.
2. Import the WSL2 image to create a new instance of it.
3. Install VS Code: It is more convenient to install it on Windows and further configure
   it from WSL2 than installing it directly inside WSL2.
4. Run the provisioning script ``whistle.bash`` inside the newly created WSL2 instance.

bash script ``whistle.bash``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This script performs various installation and configuration steps. It first executes as
the root user and then as a standard user. While running as the root user, it also
creates the standard user.

The installation and configuration steps are organized into setup bundles. Setup bundles
are of two types:

1. **core bundles**: These are always executed as they perform essential installation
   and configuration.
2. **optional bundles**: These are executed only if requested.

How to define a new setup bundle
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This section describes the steps required to define a new setup bundle, which is given
the hypothetical name ``watchdog`` for clarity of understanding. Perform the following
modifications in the ``whistle.bash`` file:

1. Decide if ``watchdog`` is a core bundle or an optional bundle. Accordingly, add an
   item to the ``EXECUTE_BUNDLE`` associative array.

   *Core bundle*

   .. code-block:: bash
      :caption: watchdog is a core bundle

      EXECUTE_BUNDLE=(
      ...
          [watchdog]=1
      )

   *Optional bundle*

   .. code-block:: bash
      :caption: watchdog is an optional bundle

      EXECUTE_BUNDLE=(
      ...
          [watchdog]=0
      )

2. Determine if the ``watchdog`` bundle should be executed as the root user or as
   the standard user. This determines the placement of its installation and
   configuration steps block (described in the next step). You may also execute it in
   two parts, first as the root user and then as the standard user.

   * To execute it as the root user, the installation and configuration block needs to
     be inside the following ``if`` ... ``fi`` block:

     .. code-block:: bash
        :caption: Execute watchdog as the root user

        if [[ $EUID -eq 0 ]]; then
        ...
        # watchdog's installation and configuration block (described in the next step)
        # needs to go here.
        ...
        fi

   * To execute it as the standard user, the installation and configuration block needs
     to be outside *and* after the above-mentioned ``if`` ... ``fi`` block.

     .. pull-quote:: \:bulb: **TIP**

        To preserve any environment variables when the script switches from the root
        user to the standard user, append it to the ``--preserve-env`` argument of the
        ``exec sudo`` command:

        .. code-block:: bash
           :caption: preserving environment variables when switching to the standard user
           :highlight-lines: 2

           echo "Switching to the standard user for further configuration..."
           exec sudo \
           --preserve-env=USERNAME,PATH,WSL_DISTRO_NAME \
           --login \
           --user "$DEFAULT_USER" \
           "$(realpath $0)" "${ARGUMENTS[@]}"

3. Define the installation and configuration steps for ``watchdog`` in
   an ``if`` ... ``fi`` block:

   .. code-block:: bash
      :caption: installation and configuration steps for the watchdog bundle

      if [ "${EXECUTE_BUNDLE[watchdog]}" -eq 1 ]; then
          echo "Installing watchdog..."

          # Add installation and configuration steps for watchdog here
          sudo apt-get install -yq example-watchdog
          export PATH="$PATH:/usr/bin/example-watchdog" | tee -a /home/$DEFAULT_USER/.profile
          ...
      fi

   * **VS Code extensions** (optional): Suitable VS Code extensions may be
     specified for installation in the installation and configuration block:

     .. code-block:: bash
        :caption: Specifying VS Code extensions

        VSCODE_EXTENSIONS+=(\
            "whistleblower.watchdog.bark", \
            "whistleblower.watchdog.bite" \
        )

4. Update the ``display_help()`` function mentioning the ``watchdog`` setup bundle,
   with additional explanation if necessary.

Sponsoring
----------

If you like ``whistle`` and you are doing well in life, you can sponsor it. You can
make a recurring or a one-time contribution with any amount of your choice. My finances
are thankfully in a reasonably healthy state, so the sponsorship is for you to feel
good about supporting what you found useful.

.. pull-quote:: \:pray: **CREDIT**

   The text of the above message is inspired by `agadmator's Excellent Subscribers video <https://youtu.be/wlPl__FzaTI?si=hVwbV0tAUwyWMpTF>`_.

**Sponsoring options**

Sponsor using one of the following options:

.. raw:: html

   <a href="https://github.com/sponsors/dragondive"><img src="https://img.shields.io/badge/Github-%E2%9E%9C-black?style=for-the-badge&logo=github" alt="Github - ➜"></a>
   <br>
   <a href="https://buymeacoffee.com/dragondive"><img src="https://img.shields.io/badge/Buy_me_a_coffee-%E2%9E%9C-black?style=for-the-badge&logo=buymeacoffee" alt="Buy me a coffee - ➜"></a>

|

You can also sponsor directly with Unified Payments Interface (UPI) :fire:, if you are
Indian :india: or in a country that supports remittance by UPI to India. Scan the below
QR code or use my UPI id ``apai@upi``.

.. raw:: html

   <div align="center">
      <a href="upi://pay?pa=apai@upi&pn=Aravind%20%20Pai&cu=INR&mode=02&purpose=00&orgid=189999&sign=1pB+zZ+Dp+6ACZlEhfuzNf90Guvoh6QoE/0zlgetfhcN65/L6BULimTDkH5gPm2roKSh62NDYcLAXLlUA8zQPZpy6sOqpfVeyklufuWsE2cA7bGR4l8whufvlgC8p4v66UZB7IuCKIlfgcOuMpYSY1kRI+EEuN5DLaiQyjpd/bI=">
         <img src="https://raw.githubusercontent.com/dragondive/.github/refs/heads/main/apai_upi_qrcode.jpg" alt="upi://pay?pa=apai@upi&pn=Aravind%20%20Pai&cu=INR&mode=02&purpose=00&orgid=189999&sign=1pB+zZ+Dp+6ACZlEhfuzNf90Guvoh6QoE/0zlgetfhcN65/L6BULimTDkH5gPm2roKSh62NDYcLAXLlUA8zQPZpy6sOqpfVeyklufuWsE2cA7bGR4l8whufvlgC8p4v66UZB7IuCKIlfgcOuMpYSY1kRI+EEuN5DLaiQyjpd/bI=" title="sponsor dragondive" width="200">
      </a>
   </div>

Frequently Asked Questions
--------------------------

.. pull-quote:: \:question: **Question**

   Why doesn't ``whistle`` have a setup bundle for *<a language or technology that
   I use or prefer>*?

.. pull-quote:: \:speech_balloon: **Answer**

   The current ``whistle`` is a minimal working utility. I released it so that it
   grows with developer community's contributions. You are welcome to contribute more
   setup bundles. Refer `Contributor Documentation`_ for more information. I also plan
   to add more setup bundles in the future.

|

.. pull-quote:: \:question: **Question**

   Can the *X* setup bundle include tool *Y* or exclude tool *Z* because that's my
   team's setup at work?

.. pull-quote:: \:speech_balloon: **Answer**

   Sure! You may modify any setup bundle in ``whistle.bash`` to suit your preference.
   Please consider contributing your changes back to ``whistle`` if it would be useful
   to other developers.

|

.. pull-quote:: \:question: **Question**

   I don't like VS Code, I prefer using the *X* IDE instead. Why does ``whistle`` force
   me to use VS Code?

.. pull-quote:: \:speech_balloon: **Answer**

   You are not forced to use VS Code. You can modify the ``whistle`` script to install
   and configure your preferred IDE. You can even get rid of the VS Code setup.

   ``whistle`` started as my personal utility project. I regularly use many programming
   languages, such as Python, Java, C++, Rust and Go. I also frequently write scripts
   in bash and powershell. Besides, I routinely work with multiple markup and
   configuration formats, such as Markdown, RST, CSV, TOML, YAML, INI and JSON.
   A general-purpose IDE is more convenient even if it lacks some features of the
   language-specific IDEs.

   VS Code works seamlessly with minimal hassles on Windows, WSL2 running on Windows,
   *and* docker containers running inside that WSL2. Other IDEs have not offered me a
   smooth experience in this area.

|

.. pull-quote:: \:question: **Question**

   Can I use ``whistle`` to install the *X* flavour of Linux instead of Ubuntu?

.. pull-quote:: \:speech_balloon: **Answer**

   Yes, certainly. You are free to enhance ``whistle`` to make the Linux flavour
   configurable. Please consider contributing your enhancement back to the community
   as well.

|

.. pull-quote:: \:question: **Question**

   Why do you want the user to modify your code to get it working for them? Isn't that
   a poor design or even an anti-pattern?

.. pull-quote:: \:speech_balloon: **Answer**

   For any general-purpose utliity, that would indeed be a poor design. However,
   ``whistle`` is meant primarily for developers. Developers are expected to be able to
   adapt a powershell and a bash script, even with no prior scripting experience, so I do
   consider this a problem.

   Moreover, it is not practical to create a configuration script that fits everyone's
   needs exactly. However, if there is sufficient interest from the community, I would
   consider refactoring to configure the setup bundles through a YAML or TOML
   configuration file.

|

.. pull-quote:: \:question: **Question**

   Why do you consider docker to be a core bundle?

.. pull-quote:: \:speech_balloon: **Answer**

   Docker is the most commonly used containerization technology. Personally, I strongly
   prefer using tools through their docker container instead of the local installation.
   Local installation often leads to mess and clutter, along with the occasional
   dependency hells. Moreover, trying out and comparing various versions of tools is a
   breeze with docker.

|

.. pull-quote:: \:question: **Question**

   What was your motivation to create ``whistle``?

.. pull-quote:: \:speech_balloon: **Answer**

   We humans have created many great things in this world. We have also created the
   Windows operating system, which many developers end up using instead of Linux.
   This has also led to the creation of the Windows Subsystem for Linux (WSL).

   The `standard approach <https://learn.microsoft.com/en-us/windows/wsl/install>`_ of
   installing only one instance of a WSL release was highly limiting for a lot of my
   development work. I discovered the lesser known option of importing a WSL image,
   which could be used to create multiple instances. However, that still requires some
   configuration to be usable. There were also several steps I performed repeatedly to
   setup my WSL instances. The logical next step was to automate.

   Having enjoyed the flexibility of multiple WSL instances—created with a single
   command line invocation—and saving hundreds of hours in the process, I decided to
   share my work with the developer community, for the benefit of developers who need
   to use Windows.
