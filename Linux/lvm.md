# Linux 勉強会

## テーマ lvmの作成

### 手順

1 ディスクの状態確認

```
  # fdisk -l

  Disk /dev/sda: 16.1 GB, 16105819648 bytes, 31456679 sectors
  Units = sectors of 1 * 512 = 512 bytes
  Sector size (logical/physical): 512 bytes / 512 bytes
  I/O size (minimum/optimal): 512 bytes / 512 bytes
  Disk label type: dos
  Disk identifier: 0x0008ad61

     Device Boot      Start         End      Blocks   Id  System
  /dev/sda1   *        2048      616447      307200   83  Linux
  /dev/sda2          616448    10856447     5120000   83  Linux
  /dev/sda3        10856448    16715775     2929664   82  Linux swap / Solaris
  /dev/sda4        16715776    31455231     7369728    5  Extended
  /dev/sda5        16717824    31062015     7172096   8e  Linux LVM

  Disk /dev/sdb: 8589 MB, 8589934592 bytes, 16777216 sectors
  Units = sectors of 1 * 512 = 512 bytes
  Sector size (logical/physical): 512 bytes / 512 bytes
  I/O size (minimum/optimal): 512 bytes / 512 bytes


  Disk /dev/mapper/VG001-root: 7340 MB, 7340032000 bytes, 14336000 sectors
  Units = sectors of 1 * 512 = 512 bytes
  Sector size (logical/physical): 512 bytes / 512 bytes
  I/O size (minimum/optimal): 512 bytes / 512 bytes

  #
```
/dev/sdaと/dev/sdbの２本のディスクがあることがわかる。  
今回は、/dev/sdb全てをlvmとして構成する。

2 パーティションの構成の作成

```
  # parted /dev/sdb
  GNU Parted 3.1
  Using /dev/sdb
  Welcome to GNU Parted! Type 'help' to view a list of commands.
  (parted)                                                                  
  (parted)                                                                  
  (parted) p                                                                 
  Error: /dev/sdb: unrecognised disk label
  Model: ATA VBOX HARDDISK (scsi)                                           
  Disk /dev/sdb: 8590MB
  Sector size (logical/physical): 512B/512B
  Partition Table: unknown
  Disk Flags:

  (parted) help                                                             
    align-check TYPE N                        check partition N for TYPE(min|opt) alignment
    help [COMMAND]                           print general help, or help on COMMAND
    mklabel,mktable LABEL-TYPE               create a new disklabel (partition table)
    mkpart PART-TYPE [FS-TYPE] START END     make a partition
    name NUMBER NAME                         name partition NUMBER as NAME
    print [devices|free|list,all|NUMBER]     display the partition table, available devices,
          free space, all found partitions, or a particular partition
    quit                                     exit program
    rescue START END                         rescue a lost partition near START and END
    rm NUMBER                                delete partition NUMBER
    select DEVICE                            choose the device to edit
    disk_set FLAG STATE                      change the FLAG on selected device
    disk_toggle [FLAG]                       toggle the state of FLAG on selected device
    set NUMBER FLAG STATE                    change the FLAG on partition NUMBER
    toggle [NUMBER [FLAG]]                   toggle the state of FLAG on partition NUMBER
    unit UNIT                                set the default unit to UNIT
    version                                  display the version number and copyright
          information of GNU Parted
  (parted)mklabel mkdos                                                         
  (parted) p                                                                
  Model: ATA VBOX HARDDISK (scsi)
  Disk /dev/sdb: 8590MB
  Sector size (logical/physical): 512B/512B
  Partition Table: msdos
  Disk Flags:

  Number  Start  End  Size  Type  File system  Flags

  (parted) mkpart                                                           
  Partition type?  primary/extended? primary                                
  File system type?  [ext2]?                                                
  Start? 0%                                                                 
  End? 8590                                                                 
  (parted)                                                                  
  (parted)                                                                  
  (parted) p                                                                
  Model: ATA VBOX HARDDISK (scsi)
  Disk /dev/sdb: 8590MB
  Sector size (logical/physical): 512B/512B
  Partition Table: msdos
  Disk Flags:

  Number  Start   End     Size    Type     File system  Flags
   1      1049kB  8590MB  8589MB  primary

  (parted)                                                                  
  (parted)                                                                  
  (parted) set 1 lvm on                                                     
  (parted) p                                                                
  Model: ATA VBOX HARDDISK (scsi)
  Disk /dev/sdb: 8590MB
  Sector size (logical/physical): 512B/512B
  Partition Table: msdos
  Disk Flags:

  Number  Start   End     Size    Type     File system  Flags
   1      1049kB  8590MB  8589MB  primary               lvm


  (parted) q                                                                
  Information: You may need to update /etc/fstab.

```
パーティションテーブルが未設定のため、msdos(MBR)を設定。  
全ての領域をパーティションsdb1へ割り当てる。  
その後、lvmのフラグを立てる事を忘れない。

_Tips_  
  一つ目のパーティションを作成する場合、スタート位置がわからない時がある。
  その時は0%とすると、スタート位置を自動で調整してくれる。  
  また、全ての領域を割り当てる場合、エンド位置を100%とするとエンド位置も自動調整してくれる。


3 物理ボリュームの作成

```
  # pvcreate /dev/sdb1
  Physical volume "/dev/sdb1" successfully created.
  #
  #
  # pvscan
  PV /dev/sda5   VG VG001           lvm2 [6.84 GiB / 0    free]
  PV /dev/sdb1                      lvm2 [8.00 GiB]
  Total: 2 [14.83 GiB] / in use: 1 [6.84 GiB] / in no VG: 1 [8.00 GiB]
  #

```

4 ボリュームグループの作成

```
  # vgcreate -s 8m VolGroup00 /dev/sdb1
  Volume group "VolGroup00" successfully created

```

ボリュームグループを作成する際には、エクステントサイズを考慮する必要がある。  
PEには上限があります。（65536個まで）

_簡単な計算方法_  
・VG作成時のデフォルトPE容量は4MBです。これを例にすると以下の計算式で上限が求められます。  
65536 × 1024 × 1024 × 4 = 2.748779e11 byte （256GB）

|PEサイズ|LVMで扱える最大容量|
|:--:|:--:|
|4MB|256GB|
|8MB|512GB|
|16MB|1TB|
|32MB|2TB|
|64MB|4TB|

→ 今回は8GBしかないので、エクステントサイズは4MBにする。

5 ボリュームグループのステータス確認

```
  # vgdisplay -v VolGroup00
  --
    VG Name               VolGroup00
    System ID             
    Format                lvm2
    Metadata Areas        1
    Metadata Sequence No  1
    VG Access             read/write
    VG Status             resizable
    MAX LV                0
    Cur LV                0
    Open LV               0
    Max PV                0
    Cur PV                1
    Act PV                1
    VG Size               8.00 GiB
    PE Size               4.00 MiB
    Total PE              2047
    Alloc PE / Size       0 / 0   
    Free  PE / Size       2047 / 8.00 GiB
    VG UUID               wmiTen-APrS-sZAC-4Gqc-gsXi-0mPf-b623x9

    --- Physical volumes ---
    PV Name               /dev/sdb1     
    PV UUID               jIc9Ut-0NhY-6HPX-3jiy-MLmN-Kqzk-1NaEcG
    PV Status             allocatable
    Total PE / Free PE    2047 / 2047
```

6 LVの作成

```
  # lvcreate -l 2047 -n vol00 VolGroup00
  Logical volume "vol00" created.
  # lvdisplay
  --- Logical volume ---
  LV Path                /dev/VolGroup00/vol00
  LV Name                vol00
  VG Name                VolGroup00
  LV UUID                HQnTSj-HefF-MmfQ-JrP9-s4ED-7FwZ-xXLfyo
  LV Write Access        read/write
  LV Creation host, time localhost.localdomain, 2017-10-08 22:16:26 +0900
  LV Status              available
  # open                 0
  LV Size                8.00 GiB
  Current LE             2047
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:1

```

7 ファイルシステムのフォーマット

```
  # mkfs.xfs /dev/VolGroup00/vol00
  meta-data=/dev/VolGroup00/vol00  isize=512    agcount=4, agsize=524032 blks
           =                       sectsz=512   attr=2, projid32bit=1
           =                       crc=1        finobt=0, sparse=0
  data     =                       bsize=4096   blocks=2096128, imaxpct=25
           =                       sunit=0      swidth=0 blks
  naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
  log      =internal log           bsize=4096   blocks=2560, version=2
           =                       sectsz=512   sunit=0 blks, lazy-count=1
  realtime =none                   extsz=4096   blocks=0, rtextents=0
```
