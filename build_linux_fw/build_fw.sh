#!/bin/sh

# 0. Чистка "мусора"
rm -f ./output_1/*
rm -f ./output_2/*
sleep 1

# Все действия будут происходить в директории output, там же будет лежать полученный образ флеш памяти на 4Мб - fullflash_linux_4m.bin.
# Полученный образ надо будет прошить утилитой gxdownloader через RS-232, для ряда устройств RS-232 должен быть "честным", а не TTL.

# 1. Подписываем kernel пожатый в lzma для загрузчика gxboot(он же u-boot)
./tools/mkimage -O linux -A sandbox -T kernel -C lzma -a 90000000 -e 90000000 -n "Linux-2.6.27.55" -d ./src_fw_1/vmlinux.lzma ./output_1/uImage
./tools/mkimage -O linux -A sandbox -T kernel -C lzma -a 90000000 -e 90000000 -n "Linux-2.6.27.55" -d ./src_fw_2/vmlinux.lzma ./output_2/uImage

# 2. Из src_fw/ копируем загрузчик для gx6605s в output/, а так же "пустышку" для перезаписываемой файловой системы minifs
#    (нет для нее исходников и информации), она тоже может пригодится в будущем для хранения и редактирования конфигов, пока просто заполняем ей
#    не используемое пространство на флеше до самого конца.
cp -f ./src_fw_1/*.bin ./output_1/
cp -f ./src_fw_2/*.bin ./output_2/

# 3. Создаем rootfs с файловой системой squashfs lzma
./tools/mksquashfs ./src_fw_1/squashfs-root ./output_1/rootfs.bin -noappend -no-duplicates
./tools/mksquashfs ./src_fw_2/squashfs-root ./output_2/rootfs.bin -noappend -no-duplicates

# 4. Скопируем из src_fw/ конфигурацию для 4Мб флеша flash.conf(внутри есть комментарии что к чему) в output/
cp -f ./src_fw_1/*.conf ./output_1/
cp -f ./src_fw_2/*.conf ./output_2/

# 5. Собираем образ full флеша для прошивки в устройство
cd ./output_1
../tools/genflash mkflash ./flash.conf fullflash_linux_4m_1.bin
cd ..
cd ./output_2
../tools/genflash mkflash ./flash.conf fullflash_linux_4m_2.bin
cd ..

# 6. Сообщение как прошить полученный образ. 
#    В gxdownloader_linux/ есть небольшой README, перед прошивкой желательно сделать бэкап своей родной прошивки!

echo "Use command for burn flash:"
echo "./gxdownloader_linux/boot.elf -b ./gxdownloader_linux/gx6605s-generic-sflash.boot -d /dev/ttyUSB0 -c serialdown 0 ./output_1/fullflash_linux_4m_1.bin"
echo "or"
echo "./gxdownloader_linux/boot.elf -b ./gxdownloader_linux/gx6605s-generic-sflash.boot -d /dev/ttyUSB0 -c serialdown 0 ./output_2/fullflash_linux_4m_2.bin"

sleep 5
