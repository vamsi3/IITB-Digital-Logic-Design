import serial
import os

baud_rate = 2400
usb_path = '/dev/ttyXRUSB'

out = os.popen('ls {}*'.format(usb_path)).read()
out = str(out)
out = out.replace(usb_path, '')
out = out.replace('\n', ' ')
vals = out.split()

usb_path0 = usb_path + vals[0]
usb_path1 = usb_path + vals[1]

with serial.Serial(usb_path0, baud_rate, timeout=0.01) as ser0:
    with serial.Serial(usb_path1, baud_rate, timeout=0.01) as ser1:
        while True:
            inp0 = ser0.read()
            inp1 = ser1.read()
            if inp0 != b'':
                ser1.write(inp0)
                print("Writing to {}: {}".format(usb_path1, inp0.hex()))
            if inp1 != b'':
                ser0.write(inp1)
                print("Writing to {}: {}".format(usb_path0, inp1.hex()))
