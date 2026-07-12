PS C:\Temp\K9\phh-v222\system-quack-arm64-ab-gapps.img> format-Hex .\system-quack-arm64-ab-gapps.img -Count 4

   Label: C:\Temp\K9\phh-v222\system-quack-arm64-ab-gapps.img\system-quack-arm64-ab-gapps.img

          Offset Bytes                                           Ascii
                 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
          ------ ----------------------------------------------- -----
0000000000000000 3A FF 26 ED                                     :ÿ&í

PS C:\Temp\K9\phh-v222\system-quack-arm64-ab-gapps.img> cd..
PS C:\Temp\K9\phh-v222> cd..
PS C:\Temp\K9> cd .\platformtools\
PS C:\Temp\K9\platformtools> .\fastboot.exe devices
OUKITELK90000693         fastboot
PS C:\Temp\K9\platformtools> .\fastboot.exe erase system
******** Did you mean to fastboot format this ext4 partition?
Erasing 'system'                                   OKAY [  0.091s]
Finished. Total time: 0.122s
PS C:\Temp\K9\platformtools> .\fastboot.exe flash system .\system-quack-arm64-ab-gapps.img
Warning: skip copying system image avb footer due to sparse image.
Sending sparse 'system' 1/18 (131068 KB)           OKAY [ 43.114s]
Writing 'system'                                   OKAY [  1.727s]
Sending sparse 'system' 2/18 (131068 KB)           OKAY [ 43.244s]
Writing 'system'                                   OKAY [  1.760s]
Sending sparse 'system' 3/18 (130532 KB)           OKAY [ 42.918s]
Writing 'system'                                   OKAY [  1.732s]
Sending sparse 'system' 4/18 (131068 KB)           OKAY [ 43.189s]
Writing 'system'                                   OKAY [  1.748s]
Sending sparse 'system' 5/18 (130520 KB)           OKAY [ 42.892s]
Writing 'system'                                   OKAY [  1.726s]
Sending sparse 'system' 6/18 (131068 KB)           OKAY [ 43.204s]
Writing 'system'                                   OKAY [  1.747s]
Sending sparse 'system' 7/18 (130520 KB)           OKAY [ 43.040s]
Writing 'system'                                   OKAY [  1.732s]
Sending sparse 'system' 8/18 (131068 KB)           OKAY [ 43.139s]
Writing 'system'                                   OKAY [  1.747s]
Sending sparse 'system' 9/18 (130520 KB)           OKAY [ 42.958s]
Writing 'system'                                   OKAY [  1.739s]
Sending sparse 'system' 10/18 (131068 KB)          OKAY [ 43.124s]
Writing 'system'                                   OKAY [  1.732s]
Sending sparse 'system' 11/18 (131068 KB)          OKAY [ 43.087s]
Writing 'system'                                   OKAY [  1.747s]
Sending sparse 'system' 12/18 (131068 KB)          OKAY [ 42.989s]
Writing 'system'                                   OKAY [  1.739s]
Sending sparse 'system' 13/18 (131068 KB)          OKAY [ 43.006s]
Writing 'system'                                   OKAY [  1.747s]
Sending sparse 'system' 14/18 (131068 KB)          OKAY [ 43.204s]
Writing 'system'                                   OKAY [  1.733s]
Sending sparse 'system' 15/18 (131068 KB)          OKAY [ 43.012s]
Writing 'system'                                   OKAY [  1.746s]
Sending sparse 'system' 16/18 (131068 KB)          OKAY [ 43.082s]
Writing 'system'                                   OKAY [  1.740s]
Sending sparse 'system' 17/18 (130560 KB)          OKAY [ 43.162s]
Writing 'system'                                   OKAY [  1.740s]
Sending sparse 'system' 18/18 (54912 KB)           OKAY [ 18.340s]
Writing 'system'                                   OKAY [  0.788s]
Finished. Total time: 781.423s
PS C:\Temp\K9\platformtools> .\fastboot.exe -w
Erasing 'userdata'                                 OKAY [  1.168s]
mke2fs 1.47.2 (1-Jan-2025)
Creating filesystem with 14013435 4k blocks and 3506176 inodes
Filesystem UUID: 80cb880e-7ad2-11f1-8386-8743fd20de67
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
        4096000, 7962624, 11239424

Allocating group tables: done
Writing inode tables: done
Creating journal (65536 blocks): done
Writing superblocks and filesystem accounting information: done

Warning: skip copying userdata image avb footer due to sparse image.
Sending 'userdata' (364 KB)                        OKAY [  0.157s]
Writing 'userdata'                                 OKAY [  0.499s]
Erasing 'cache'                                    OKAY [  0.026s]
mke2fs 1.47.2 (1-Jan-2025)
128-byte inodes cannot handle dates beyond 2038 and are deprecated
Creating filesystem with 110592 4k blocks and 110592 inodes
Filesystem UUID: 815d6558-7ad2-11f1-885e-cb2606adfa80
Superblock backups stored on blocks:
        32768, 98304

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

Warning: skip copying cache image avb footer due to sparse image.
Sending 'cache' (72 KB)                            OKAY [  0.061s]
Writing 'cache'                                    OKAY [  0.143s]
Erasing 'metadata'                                 OKAY [  0.023s]
Erase successful, but not automatically formatting.
File system type raw data not supported.
Finished. Total time: 2.567s
PS C:\Temp\K9\platformtools> .\fastboot.exe reboot
Rebooting                                          OKAY [  0.008s]
Finished. Total time: 0.019s
PS C:\Temp\K9\platformtools>