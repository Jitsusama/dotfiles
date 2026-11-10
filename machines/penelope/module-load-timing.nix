# The desk's monitor shows nothing of penelope's boot until amdgpu starts,
# and in the boot of 2026-11-10 that came 6.2 s after btrfs loaded: loading
# amdgpu took that long before its own start ran, the module loader spent 6.3
# s of CPU, and every other module udev loaded meanwhile waited with it.
# What takes the time inside the kernel's module loader isn't known: its
# module is 36 MB with 3.2 MB of BTF, and none of it can be timed without
# root. These kernel probes put each step of every module's load in the
# kernel's log with its time, which Joel's account can read: the
# decompression, the signature check, the symbols, the relocations, the
# BTF the kernel reads as a module comes, and its start. The info pointer
# ties each load's steps together, since udev loads several at once. This
# file and its import come out after the next boot is read.
_: {
  boot.kernelParams = [
    "tp_printk"
    (builtins.concatStringsSep ";" [
      "kprobe_event=p:lm,load_module,info=$arg1:x64"
      "r:decr,module_decompress,info=$arg1:x64"
      "r:sigr,module_sig_check,info=$arg1:x64,ret=$retval"
      "p:syms,simplify_symbols,info=$arg2:x64"
      "p:rel,apply_relocations,info=$arg2:x64"
      "p:post,post_relocation,info=$arg2:x64"
      "p:form,complete_formation,info=$arg2:x64,mod=+24($arg1):string"
      "p:btf,btf_module_notify,op=$arg2,mod=+24($arg3):string"
      "r:btfr,btf_module_notify,op=$arg2,mod=+24($arg3):string"
      "p:init,do_init_module,mod=+24($arg1):string"
      "r:initr,do_init_module,mod=+24($arg1):string"
    ])
  ];
}
