rmmod mods 2>/dev/null
modprobe -r nvidia_modeset nvidia_uvm nvidia_drm nvidia
lsof | grep /dev/nvidia
