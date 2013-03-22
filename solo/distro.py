import platform

distro = platform.dist()[0]
print distro.lower().rstrip()
