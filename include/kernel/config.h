#ifndef __CONFIG_H
#define __CONFIG_H

#define ENTRY_ADDR 0x7c00 // stands for the entry address (physical)

#define INFO_DATA_AREA_HEAD 0x8000

#define MEMORY_TABLE_HEAD INFO_DATA_AREA_HEAD
#define MEMORY_TABLE_LOW_MEM MEMORY_TABLE_HEAD
#define MEMORY_TABLE_HIGH_MEM MEMORY_TABLE_LOW_MEM+2
#define MEMORY_TABLE_CALCED_SIZE MEMORY_TABLE_HIGH_MEM+2
#define MEMORY_TABLE_END MEMORY_TABLE_CALCED_SIZE+4

#define BOOT_DRIVE_HEAD MEMORY_TABLE_END
#define BOOT_DRIVE BOOT_DRIVE_HEAD
#define BOOT_DRIVE_END BOOT_DRIVE+2
#define BOOT_DRIVE_INFO_HEAD BOOT_DRIVE_END+6
#define BOOT_DRIVE_INFO_TYPE BOOT_DRIVE_INFO_HEAD
#define BOOT_DRIVE_INFO_MAX_CYLINDERS BOOT_DRIVE_INFO_TYPE+1
#define BOOT_DRIVE_INFO_MAX_SECTORS BOOT_DRIVE_INFO_MAX_CYLINDERS+2
#define BOOT_DRIVE_INFO_MAX_HEADS BOOT_DRIVE_INFO_MAX_SECTORS+1
#define BOOT_DRIVE_INFO_RESERVED BOOT_DRIVE_INFO_MAX_HEADS+1
#define BOOT_DRIVE_INFO_END BOOT_DRIVE_INFO_MAX_HEADS+1

#define KEYBOARD_LEDS_INFO_HEAD BOOT_DRIVE_INFO_END
#define KEYBOARD_LEDS_INFO KEYBOARD_LEDS_INFO_HEAD
#define KEYBOARD_LEDS_INFO_RESERVED KEYBOARD_LEDS_INFO+1
#define KEYBOARD_LEDS_INFO_END KEYBOARD_LEDS_INFO_RESERVED+1

#endif