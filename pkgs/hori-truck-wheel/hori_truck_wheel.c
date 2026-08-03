// SPDX-License-Identifier: GPL-2.0
/*
 * HORI TRUCK CONTROL SYSTEM WHEEL (0f0d:017a) 用 HID report_fixup。
 *
 * このホイールの HID レポート記述子は 8 軸を
 *   X, Y, Z, Rx, Ry, Rz, Slider, Slider
 * と宣言しており、末尾の Slider(Usage 0x36) が 2 回重複している。
 * Windows(DirectInput) は重複を別軸として列挙するのでブレーキが見えるが、
 * Linux の HID パーサは 2 つ目の Slider も ABS_THROTTLE に割り当てようとして
 * 衝突し、その軸(=ブレーキ)を丸ごと破棄する(debugfs で 2 つ目の Slider が
 * "Sync.Report" にマップされることを確認済み)。
 *
 * ここでは 2 つ目の Slider(09 36) を Dial(09 37) に書き換える。これにより
 * Linux は別軸(ABS_RUDDER)として認識し、ブレーキペダルが有効になる。
 * ゲーム側でその軸をブレーキに割り当てれば使用可能。
 *
 * INCREMENT_USAGE_ON_DUPLICATE クオークは「Report Count が Usage 数より多く、
 * 自動補完された重複」だけを増分する実装で、この記述子のように Usage を明示的に
 * 並べたケースは対象外のため効かない。ゆえに記述子の直接書き換えが必要。
 */
#include <linux/device.h>
#include <linux/hid.h>
#include <linux/module.h>

#define USB_VENDOR_ID_HORI	0x0f0d
#define USB_DEVICE_ID_HORI_TRUCK_WHEEL	0x017a

/* 記述子中の "09 36 09 36"(Usage Slider が連続) を探し、
 * 2 つ目を "09 37"(Usage Dial) に書き換える。 */
static const __u8 *hori_wheel_report_fixup(struct hid_device *hdev, __u8 *rdesc,
					   unsigned int *rsize)
{
	unsigned int i;

	if (!rdesc || *rsize < 4)
		return rdesc;

	for (i = 0; i + 3 < *rsize; i++) {
		if (rdesc[i] == 0x09 && rdesc[i + 1] == 0x36 &&
		    rdesc[i + 2] == 0x09 && rdesc[i + 3] == 0x36) {
			rdesc[i + 3] = 0x37; /* 2 つ目 Slider -> Dial */
			hid_info(hdev,
				 "HORI truck wheel: split duplicate Slider usage; brake axis now exposed (ABS_RUDDER)\n");
			break;
		}
	}

	return rdesc;
}

static const struct hid_device_id hori_wheel_devices[] = {
	{ HID_USB_DEVICE(USB_VENDOR_ID_HORI, USB_DEVICE_ID_HORI_TRUCK_WHEEL) },
	{ }
};
MODULE_DEVICE_TABLE(hid, hori_wheel_devices);

static struct hid_driver hori_wheel_driver = {
	.name = "hori-truck-wheel",
	.id_table = hori_wheel_devices,
	.report_fixup = hori_wheel_report_fixup,
};
module_hid_driver(hori_wheel_driver);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Fix HORI Truck Control System wheel duplicate Slider usage so the brake pedal works on Linux");
