# coding: utf-8
"""*****************************************************************************
* Copyright (C) 2019 Microchip Technology Inc. and its subsidiaries.
*
* Subject to your compliance with these terms, you may use Microchip software
* and any derivatives exclusively with Microchip products. It is your
* responsibility to comply with third party license terms applicable to your
* use of third party software (including open source software) that may
* accompany Microchip software.
*
* THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS". NO WARRANTIES, WHETHER
* EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED
* WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A
* PARTICULAR PURPOSE.
*
* IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,
* INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND
* WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS
* BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE. TO THE
* FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S TOTAL LIABILITY ON ALL CLAIMS IN
* ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF ANY,
* THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
*****************************************************************************"""

###################################################################################################
########################################## Component ##############################################
###################################################################################################
def instantiateComponent(powerComponent):
    # DRMEN symbol

    clkValGrp_OSCCON__DRMEN = ATDF.getNode('/avr-tools-device-file/modules/module@[name="OSC"]/value-group@[name="OSCCON__DRMEN"]')
    if clkValGrp_OSCCON__DRMEN is None:
        clkValGrp_OSCCON__DRMEN = ATDF.getNode('/avr-tools-device-file/modules/module@[name="CRU"]/value-group@[name="OSCCON__DRMEN"]')
    
    if clkValGrp_OSCCON__DRMEN is not None:
        dreamModeExist = powerComponent.createBooleanSymbol("DREAM_MODE_EXIST", None)
        dreamModeExist.setDefaultValue(True)
        dreamModeExist.setVisible(False)

    coreArch = Database.getSymbolValue("core", "CoreArchitecture")

    if (ATDF.getNode('/avr-tools-device-file/modules/module@[name="DSCTRL"]') != None) or (ATDF.getNode('/avr-tools-device-file/modules/module@[name="DSCON"]') is not None):
        deepSleepSymMenu = powerComponent.createMenuSymbol("DEEP_SLEEP_MODE_MENU", None)
        deepSleepSymMenu.setLabel("Deep Sleep Mode Configuration")

        deepSleepSymExist = powerComponent.createBooleanSymbol("DEEP_SLEEP_MODE_EXIST", deepSleepSymMenu)
        deepSleepSymExist.setVisible(False)
        deepSleepSymExist.setDefaultValue(True)

        if coreArch == "MIPS":
            execfile(Variables.get("__CORE_DIR") + "/../peripheral/power/config/power_pic32m.py")
        else:
            execfile(Variables.get("__CORE_DIR") + "/../peripheral/power/config/power_pic32c.py")