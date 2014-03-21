/*
 *  RainMachine v2 board support
 *
 *  Copyright (C) 2013-2014 Nicu Pavel <npavel@linuxconsulting.ro>
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License version 2 as published
 *  by the Free Software Foundation.
 */

#include <linux/gpio.h>
#include <linux/platform_device.h>
#include <asm/mach-ath79/ath79.h>
#include <asm/mach-ath79/ar71xx_regs.h>
#include <asm/mach-ath79/ag71xx_platform.h>

#include <linux/i2c.h>
#include <linux/i2c-algo-bit.h>
#include "linux/i2c-gpio.h"
#include "linux/platform_device.h"

#include "common.h"
#include "dev-eth.h"
#include "dev-gpio-buttons.h"
#include "dev-leds-gpio.h"
#include "dev-m25p80.h"
#include "dev-usb.h"
#include "dev-wmac.h"
#include "machtypes.h"

#undef ENABLE_LAN
#undef ENABLE_WATCHDOG

#define RAINMACHINE_GPIO_BTN_RESET	11

#define RAINMACHINE_GPIO_LED_WLAN	0
#define RAINMACHINE_GPIO_LED_WAN	13
#define RAINMACHINE_GPIO_LED_LAN1	14
#define RAINMACHINE_GPIO_LED_LAN2	15
#define RAINMACHINE_GPIO_LED_LAN3	16
#define RAINMACHINE_GPIO_LED_LAN4	17

#define RAINMACHINE_KEYS_POLL_INTERVAL	20	/* msecs */
#define RAINMACHINE_KEYS_DEBOUNCE_INTERVAL (3 * RAINMACHINE_KEYS_POLL_INTERVAL)

static const char *rainmachine_part_probes[] = {
	"tp-link",
	NULL,
};

static struct flash_platform_data rainmachine_flash_data = {
	.part_probes	= rainmachine_part_probes,
};

static struct gpio_led rainmachine_leds_gpio[] __initdata = {
	 {
		.name		= "tp-link:green:wlan",
		.gpio		= RAINMACHINE_GPIO_LED_WLAN,
		.active_low	= 0,
	},
};

static struct gpio_keys_button rainmachine_gpio_keys[] __initdata = {
	{
		.desc		= "reset",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = RAINMACHINE_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= RAINMACHINE_GPIO_BTN_RESET,
		.active_low	= 0,
	}
};

struct led_platform_data pca9952_data = {
     .num_leds = 16,
};

static struct platform_device rmvalve_device = {
        .name           = "rmvalves",
        .id             = -1,
};

/*
static struct resource rainmachine_gpio_resources[] = {
        {
                .name = "gpio",
                .start  = AR933X_GPIO_MASK,
                .end    = AR933X_GPIO_MASK,
                .flags  = 0,
        },
};

static struct platform_device rainmachine_gpio = {
        .name         = "GPIODEV",
        .id         = -1,
        .num_resources  = ARRAY_SIZE(rainmachine_gpio_resources),
        .resource       = rainmachine_gpio_resources,
};
*/

static struct i2c_gpio_platform_data rainmachine_i2c_gpio_data = {
       .sda_pin = 18,
       .scl_pin = 22,
};
       
static struct platform_device rainmachine_i2c_gpio = {
       .name = "i2c-gpio",
       .id   = 0,
       .dev  = {
               .platform_data = &rainmachine_i2c_gpio_data,
       },
};

/* register i2c devices */
static struct i2c_board_info rainmachine_i2c_devs[] __initdata = {
	{ I2C_BOARD_INFO("rmtouch", 0x44), }, /* 1000100x - Touch/Proximity controller */
	{ I2C_BOARD_INFO("pcf8523", 0x68), }, /* 1101000x - RTC */
	{ 
		I2C_BOARD_INFO("pca9552", 0x67),
		.platform_data = &pca9952_data,
	}, /* 1100111x - Display/Led controller */
};

/*
static struct platform_device *rainmachine_devices[] __initdata = {
        &rainmachine_gpio,
	&rainmachine_i2c_gpio
};
*/

static void __init rainmachine_setup(void)
{
	u8 *mac = (u8 *) KSEG1ADDR(0x1f01fc00);
	u8 *ee = (u8 *) KSEG1ADDR(0x1fff1000);

	/* i2c devices */
	/*platform_add_devices(rainmachine_devices, ARRAY_SIZE(rainmachine_devices));*/
	i2c_register_board_info(0, rainmachine_i2c_devs, ARRAY_SIZE(rainmachine_i2c_devs));
	platform_device_register(&rainmachine_i2c_gpio);
	platform_device_register(&rmvalve_device);


#ifdef ENABLE_LAN
	ath79_setup_ar933x_phy4_switch(true, true);

	ath79_gpio_function_disable(AR933X_GPIO_FUNC_ETH_SWITCH_LED0_EN |
				    AR933X_GPIO_FUNC_ETH_SWITCH_LED1_EN |
				    AR933X_GPIO_FUNC_ETH_SWITCH_LED2_EN |
				    AR933X_GPIO_FUNC_ETH_SWITCH_LED3_EN |
				    AR933X_GPIO_FUNC_ETH_SWITCH_LED4_EN);
#endif

	ath79_register_leds_gpio(-1, ARRAY_SIZE(rainmachine_leds_gpio),
				 rainmachine_leds_gpio);

	ath79_register_gpio_keys_polled(1, RAINMACHINE_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(rainmachine_gpio_keys),
					rainmachine_gpio_keys);

	ath79_register_m25p80(&rainmachine_flash_data);
	/* ath79_register_usb(); */

#ifdef ENABLE_LAN
	ath79_init_mac(ath79_eth0_data.mac_addr, mac, 1);
	ath79_init_mac(ath79_eth1_data.mac_addr, mac, -1);
#endif
	ath79_register_mdio(0, 0x0);

#ifdef ENABLE_LAN
	ath79_register_eth(1);
	ath79_register_eth(0);
#endif

#ifdef ENABLE_WATCHDOG
	ath79_register_wdt();
#endif

	ath79_register_wmac(ee, mac);
}

MIPS_MACHINE(ATH79_MACH_RAINMACHINE, "RAINMACHINE",
	     "RAINMACHINE Sprinkler v2", rainmachine_setup);
