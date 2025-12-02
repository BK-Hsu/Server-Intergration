parallel -j 18 "sshpass -p superuser ssh -o StrictHostKeyChecking=no sysadmin@{} \
  'curl -k -X POST http://172.31.13.251/redfish/v1/Chassis/HGX_ERoT_CPU_0/Actions/Oem/CAKInstall \
  -d \"{\\\"CAKKey\\\": \\\"-----BEGIN PUBLIC KEY-----\\nMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEvL/Rr06bbZPRdiKdRtGZKMCUwGh34w5+\\n7fvZncIwnD9dz2h1RPChtYBmaLfNS34duQhfyxS93cP7SZkbRqbdlWKETkA296fk\\nZO6zMPgz9lhNifgxrb+bp0MZ2KnJpwv5\\n-----END PUBLIC KEY-----\\\", \\\"LockDisable\\\": false}\"'" ::: 192.168.89.{148,149,150,152,151,153,154,159,160,161,163,162,164,165,166,168,169,129}
 
parallel -j 18 "sshpass -p superuser ssh -o StrictHostKeyChecking=no sysadmin@{} \
  'curl -k -X POST http://172.31.13.251/redfish/v1/Chassis/HGX_ERoT_CPU_1/Actions/Oem/CAKInstall \
  -d \"{\\\"CAKKey\\\": \\\"-----BEGIN PUBLIC KEY-----\\nMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEvL/Rr06bbZPRdiKdRtGZKMCUwGh34w5+\\n7fvZncIwnD9dz2h1RPChtYBmaLfNS34duQhfyxS93cP7SZkbRqbdlWKETkA296fk\\nZO6zMPgz9lhNifgxrb+bp0MZ2KnJpwv5\\n-----END PUBLIC KEY-----\\\", \\\"LockDisable\\\": false}\"'" ::: 192.168.89.{148,149,150,152,151,153,154,159,160,161,163,162,164,165,166,168,169,129}
 
parallel -j 18 "sshpass -p superuser ssh -o StrictHostKeyChecking=no sysadmin@{} \
  'curl -k -X POST http://172.31.13.251/redfish/v1/Chassis/HGX_ERoT_CPU_0/Actions/Oem/CAKLock \
  -d \"{\\\"Key\\\": \\\"-----BEGIN PUBLIC KEY-----\\nMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEZLg7tePuHhJBhd+kCejSZpdVAOZ71Bj4\\nzUlOBXs9TNiVK1xd82jtiUBnuzwPugqUA5JD142hsK1B8gVJc3fBNV4IYMKN3GD2\\nbF/Wl+mqHFCxxS7ySu6Mj1Wi8iw9BdcR\\n-----END PUBLIC KEY-----\\\"}\"'" ::: 192.168.89.{148,149,150,152,151,153,154,159,160,161,163,162,164,165,166,168,169,129}
 
parallel -j 18 "sshpass -p superuser ssh -o StrictHostKeyChecking=no sysadmin@{} \
  'curl -k -X POST http://172.31.13.251/redfish/v1/Chassis/HGX_ERoT_CPU_1/Actions/Oem/CAKLock \
  -d \"{\\\"Key\\\": \\\"-----BEGIN PUBLIC KEY-----\\nMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEZLg7tePuHhJBhd+kCejSZpdVAOZ71Bj4\\nzUlOBXs9TNiVK1xd82jtiUBnuzwPugqUA5JD142hsK1B8gVJc3fBNV4IYMKN3GD2\\nbF/Wl+mqHFCxxS7ySu6Mj1Wi8iw9BdcR\\n-----END PUBLIC KEY-----\\\"}\"'" ::: 192.168.89.{148,149,150,152,151,153,154,159,160,161,163,162,164,165,166,168,169,129}
