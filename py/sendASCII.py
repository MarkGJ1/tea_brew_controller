import serial
import threading

PORT = 'COM9'  # change to your port

ser = serial.Serial(
    port=PORT,
    baudrate=9600,
    bytesize=serial.EIGHTBITS,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_TWO,
    timeout=1
)

def reader():
    while True:
        data = ser.read(ser.in_waiting or 1)
        if data:
            print(data.decode('ascii', errors='replace'), end='', flush=True)

threading.Thread(target=reader, daemon=True).start()

print(f"Connected to {PORT} @ 9600 8N2. Press Enter to send. Ctrl+C to quit.\n")

msg = '13:30:30E\r\n'
msg3 = '23:59:59E\r\n'
msg2 = msg3[::-1]

try:
    while True:
        input()
        ser.write(msg2.encode('ascii'))
        print(f"[SENT] {msg3!r}")
except KeyboardInterrupt:
    print("\nClosing port.")
    ser.close()