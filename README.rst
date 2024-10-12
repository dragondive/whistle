Whistle
=======

``whistle`` is a utility to automatically download Ubuntu WSL images, create a new WSL2
instances and provision them.

How to use
----------

1. Download this repository as a zip file and extract it into any directory on your
   local machine.

2. Open a powershell terminal and navigate to that directory.

3. Run the following command:

   .. code-block:: powershell

    # Replace "user_chosen_name" with the desired name for your new WSL2 instance.
    # The complete list of parameters are described in a separate section below.
    PowerShell -ExecutionPolicy Bypass -File .\whistle.ps1 --WslDistroName user_chosen_name

    .. To create another instance, run it again with a different instance name!


Parameters
----------

.. list-table::
   :header-rows: 1

   * - **⠀⠀⠀Parameter⠀⠀⠀**
     - **Description**
     - **Example**
     - **Default**

   * - ``-WslDistroName``
     - Name for your new WSL2 instance.
     - ``whistleblower``, ``heavens-arena``
     - ``whistleblower``

   * - ``-ReleaseName``
     - Ubuntu release name.
       Available releases at https://cloud-images.ubuntu.com/wsl/.
     - ``noble``, ``jammy``
     - ``noble``

   * - ``-ReleaseTag``
     - Release tag of the WSL2 image to download.
       Available tags inside the chosen release directory at the above page.
     - ``current``, ``20241008``
     - ``current``

   * - ``-ReleaseArch``
     - Architecture of the WSL2 image to download.
     - ``amd64``, ``arm64``
     - ``amd64``

   * - ``-SetupArgs``
     - Arguments for the setup script `whistle.bash`
       This needs to be enclosed in *both* double quotes and single quotes.
     - ``"'-h'"``, ``"'-b python3'"``, ``"'-u dragondive -b copy-ssh-keys'"``
     - ``""``

Contributor Documentation
-------------------------

Frequently Asked Questions
--------------------------

**Q**: Why doesn't ``whistle`` have a setup bundle for *<a language or technology that
I use or prefer>*?

**A**: The current ``whistle`` is a minimal working protoype. I have released it hoping
for it to grow with the developer community contributions. You are welcome to contribute
additional setup bundles for your favourite language or technology. Refer the
`Contributor Documentation`_ for more information.

I will also be adding more setup bundles for other languages that I use.

----------

**Q**: The setup bundle for *X* does not include tool *Z*. Can it be added because my
team uses that at work?

**A**: Sure! You are welcome to modify ``whistle.bash`` to extend any setup bundle to
include additional tools you need. If you consider it would be useful to other
developers, please consider contributing it back to ``whistle`` as well.

----------

**Q**: Why do you consider docker to be a core bundle?

**A**: Docker is the most popular containerization technology in use. I have found it
convenient for a lot of development work. In particular, docker enables using tools
without creating a cluttered and messy local installation and occasional dependency
incompatibilities. Moreover, trying out and comparing various versions of tools is a
breeze with docker, as compared to local installations.

----------

**Q**: I don't like VS Code, I prefer using the *X* IDE instead. Why does ``whistle``
force me to use VS Code?

**A**: ``whistle`` started as a utility for my personal purpose. I regularly use many
progamming languages, such as Python, Java, C++, Rust and Go. Besides, I routinely work
with multiple markup and configuration languages, such as Markdown, RST, CSV, TOML,
YAML, INI and JSON. VS Code as a general-purpose IDE is more convenient even if it lacks
some features of language-specific IDEs.

Additionally, VS Code works seamlessly with minimal hassles on Windows, WSL2 running on
Windows, *and* docker containers running inside that WSL2. My experience with other IDEs
has not been smooth in this area.

However, you are not forced to use VS Code. You can modify the ``whistle.bash`` script
to install and configure your preferred IDE. You can even get rid of the VS Code setup.

----------

**Q**: Can I use ``whistle`` to install the *X* flavour of Linux instead of Ubuntu?

**A**: Yes, certainly. You are free to enhance ``whistle`` to make the Linux flavour
configurable. Please consider contributing your enhancement back to the community
as well.

----------

**Q**: Why do you want the user to modify your code to get it working for them? Isn't
that a poor design or even an anti-pattern?

**A**: For any general-purpose utility, that would indeed be a poor design. However,
``whistle`` is meant to be primarily used by developers. Developers are expected to be
able to adapt a powershell and a bash script to fit their needs, so I do not see this as
a big problem. Besides, it is not practical to create a universal configuration script
that fits everyone's needs exactly.

However, there is always room for improvement. If there is sufficient interest from the
community, I would consider refactoring to configure the setup bundles through a YAML
or TOML configuration file.

----------

**Q**: What was your motivation to create ``whistle``?

**A**: We humans have created many great things in this world. We have also created the
Windows operating system, which many developers end up using instead of Linux. Then
there is the Windows Subsystem for Linux (WSL) which makes things better.

The `standard approach <https://learn.microsoft.com/en-us/windows/wsl/install>`_ of
installing only one instance of a WSL release was highly limiting for a lot of my
development work. I discovered the less well-known option of importing a WSL image,
which could be used to create multiple instances. However, that still requires some
configuration to be usable. There were also several steps I performed repeatedly to
setup my WSL instances. That's when I decided to automate.

Having enjoyed the flexibility of multiple WSL instances—created with a single command
line invocation—and saving hundreds of hours in the process, I decided to share my work
with the developer community. I hope it helps some developers who have to use Windows.
