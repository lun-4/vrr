RESOURCES = main.lua lovr-luasocket
PROJECT_NAME = vrr_client

.PHONY = package

package: $(RESOURCES)
	zip -9r $(PROJECT_NAME).lovr $(RESOURCES)

send-%: %
	adb push --sync $< /sdcard/Android/data/org.lovr.hotswap/files/.lodr

send: send-main.lua
