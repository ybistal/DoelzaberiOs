# DoelzaberiOS

Живая система для x86-64 UEFI: работает из оперативной памяти, внутри
установщик `doelzaberi-install`, который переносит её на диск - GPT, EFI-раздел
256 МиБ, корень btrfs, GRUB для UEFI. Диски: NVMe, Intel VMD/RST, SATA/AHCI,
USB (в том числе UAS), eMMC/SD, virtio, Hyper-V.

## Состав

| Путь | Что это |
| --- | --- |
| `board/doelzaberi/` | конфигурации загрузки и образов, фрагменты ядра, файлы системы |
| `configs/DoelzaberiOS_defconfig` | конфигурация сборки |
| `package/fish`, `package/fastfetch` | пакеты, которых нет в Buildroot |

## Сборка

```sh
git clone --depth 1 https://github.com/buildroot/buildroot.git buildroot
cp -a board configs package buildroot/
make -C buildroot doelzaberi_defconfig
make -C buildroot -j"$(nproc)"
```

Готовые файлы: `buildroot/output/images/doelzaberi.iso` (живая система),
`doelzaberi-sd.img` (образ диска), `bzImage`, `rootfs.cpio`.

Ванильный Buildroot соберёт не то же самое: для UEFI-загрузки ISO нужны правки
в `fs/iso9660/` и `boot/grub2/grub.cfg`, а для пакетов - строки `source` в
`package/Config.in`. Без них в системе не будет fish и fastfetch, а ISO не
загрузится по UEFI.

## Запись на флешку

```sh
sudo dd if=buildroot/output/images/doelzaberi.iso of=/dev/sdX bs=4M status=progress oflag=direct,sync
sync
```

`/dev/sdX` - весь накопитель, не раздел. Загрузка в режиме UEFI, Secure Boot
выключен. В живой системе вход `root` / `doelzaberi`.

## Установка на диск

```sh
doelzaberi-install --list      # какие диски найдены
doelzaberi-install --dry-run   # план, ничего не пишется
doelzaberi-install             # меню, затем установка
doelzaberi-install /dev/nvme0n1
```

Установщик спрашивает имя и пароль новой учётной записи, создаёт её в группах
`wheel video audio input seat`, записывает GRUB на EFI-раздел и добавляет
запись загрузки в NVRAM. Диск, с которого загружена система, требует `--force`.

## Лицензия

GPL-2.0-or-later, см. [LICENSE](LICENSE).
