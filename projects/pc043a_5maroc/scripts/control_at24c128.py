#!/usr/bin/env python3

# REad/write to AT24C256

from smbus2 import SMBus,i2c_msg

import subprocess

import os

import sys

i2cBus = SMBus(1)  # Create a new I2C bus
i2cAddress = 0x50  #  Address of PROM on I2C bus

uidLocation = 0x10
ipLocation = 0x00

# 08:00:30:xx:xx:xx
cernPrefix = [0x08, 0x00 , 0x30]

# 08:00:30:C0:A8:xx
macPrefix = cernPrefix
macPrefix.append(0xa8)
macPrefix.append(0xc8)

# 192.168.200.XX
ipPrefix = [0xc0 , 0xa8 , 0xc8]

# Read a byte from memory location memAddress inside AT24C256 at i2cAddress on bus 
def readByte( bus, i2cAddress , memAddress ):

	nBytes = 1

	writeSetMemAddr = i2c_msg.write(i2cAddress, [memAddress,memAddress])

	#writeSetMemAddrData = list(writeSetMemAddr)
	#print(writeSetMemAddrData)

	readMemData = i2c_msg.read(i2cAddress,nBytes)

	#print(readMemData)

	status = bus.i2c_rdwr(writeSetMemAddr,readMemData)

	#	returnDataData = list(returnData)
	#	print(returnDataData)

	readMemDataData = list(readMemData)
	#	print(readMemDataData)

#	print ("Reading: i2cAddr , memAddr, dataByte" , i2cAddress , memAddress , readMemDataData[0])

	return( readMemDataData[0] )

def readBytes( bus, i2cAddress , memAddress , nBytes):
	values = []
#	print("readBytes, addr, N=" , memAddress, nBytes)
	for addr in range(memAddress, memAddress+nBytes):
#		print("ReadBytes, addr = ", addr)
		values.append(readByte( bus, i2cAddress , addr ))
	return values

def writeByte( bus, i2cAddress , memAddress , dataByte):

#	print ("writing: i2cAddr , memAddr, dataByte" , i2cAddress , memAddress , dataByte)
	writeSetMemAddr = i2c_msg.write(i2cAddress, [memAddress,memAddress,dataByte])

	status = bus.i2c_rdwr(writeSetMemAddr)

	subprocess.call(['i2cdetect', '-y', '1'], stdout=subprocess.DEVNULL,stderr=subprocess.STDOUT)

#	bus.write_byte(i2cAddress, memAddress )
#	bus.write_byte(i2cAddress, memAddress )
#	bus.write_byte(i2cAddress, dataByte )


        # return( 0 )

def writeBytes( bus, i2cAddress , memAddress , dataBytes):
	'''Write a sequence of bytes to sucessive addresses in I2C PROM at I2C address i2cAddress, starting at memory address memAddress'''
	for idx in range(len(dataBytes)):
		writeByte(bus, i2cAddress , memAddress+idx , dataBytes[idx])

def writeMAC( bus, i2cAddress , value ):
	macBytes = macPrefix
	macBytes.append(value)
	writeBytes(bus, i2cAddress , uidLocation , macBytes)

def readMAC( bus, i2cAddress  ):
	print("readMAC")
	macBytes = readBytes(bus, i2cAddress , uidLocation , 6)
	return(macBytes)

def writeIP( bus, i2cAddress , value ):
	ipBytes = ipPrefix
	ipBytes.append(value)
	writeBytes(bus, i2cAddress , ipLocation , ipBytes)

def readIP( bus, i2cAddress  ):
	print("readIP")
	ipBytes = readBytes(bus, i2cAddress , ipLocation , 4)
	return(ipBytes)



def main():
	'''
	Read/write to AT24C256 using smbus2 on Raspberry Pi
	Takes one command line argument: the  last byte of the IP/MAC address
	'''
	memAddress = 0
	nBytes = 4
	data = 101
	writeBytes( i2cBus, i2cAddress , memAddress , [ 10,11,12,13])
	print(readBytes( i2cBus, i2cAddress , memAddress ,nBytes))

	ip = int(sys.argv[1])
	print("Setting IP/MAC suffix = ", ip)

	writeMAC(i2cBus, i2cAddress ,ip)
	print(readMAC(i2cBus, i2cAddress ))

	writeIP(i2cBus, i2cAddress ,ip)
	print(readIP(i2cBus, i2cAddress ))


if __name__ == "__main__":
	main()


