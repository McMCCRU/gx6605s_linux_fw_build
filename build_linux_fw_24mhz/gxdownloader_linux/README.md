Burning Метод записи SPI-FLASH 4MB с использованием последовательного порта на приставке.

Введение:

* Программа boot.elf, запускается на компьютере с Ubuntu_64
* gx6605s-generic-sflash.boot перепрошивает вспомогательную программу прошивки в память устройства.
* loader-sflash.bin Целевой имидж на 4MB, также используется для массового производства.

Выполнить команду:
* ./boot.elf --help Получить помощью.

Записать прошивку:
* ./boot.elf -b gx6605s-generic-sflash.boot -d /dev/ttyUSB0 -c serialdown 0 loader-sflash.bin,
   где /dev/ttyUSB0 - последовательный порт USB адаптера на компьютере, подключенный к приставке.
После выполнения команды нажмите кнопку сброса на плате рядом с интерфейсом micro-usb или выключите питание!

Сохранить прошивку целиком в файл:
* ./boot.elf -b gx6605s-generic-sflash.boot -d /dev/ttyUSB0 -c serialdump 0 4194304 k1mini_flash.bin


setserial /dev/ttyUSB0 divisor 233 spd_cust

./gxdownloader_linux/boot.elf -b ./gxdownloader_linux/gx6605s-generic-sflash.boot -d /dev/ttyUSB0 -r 38400

picocom -b 115200 /dev/ttyUSB0

boot> usbdown 0 fullflash_linux_4m.bin
