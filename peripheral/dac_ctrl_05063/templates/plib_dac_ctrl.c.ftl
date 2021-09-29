/*******************************************************************************
  Digital-to-Analog Converter (${DAC_INSTANCE_NAME}) PLIB

  Company:
    Microchip Technology Inc.

  File Name:
    plib_${DAC_INSTANCE_NAME?lower_case}.c

  Summary:
    ${DAC_INSTANCE_NAME} PLIB Implementation file

  Description:
    This file defines the interface to the DAC peripheral library. This
    library provides access to and control of the associated peripheral
    instance.

*******************************************************************************/
// DOM-IGNORE-BEGIN
/*******************************************************************************
* Copyright (C) 2018 Microchip Technology Inc. and its subsidiaries.
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
*******************************************************************************/
// DOM-IGNORE-END

#include "plib_${DAC_INSTANCE_NAME?lower_case}.h"
#include "device.h"
						 
// *****************************************************************************
// *****************************************************************************
// Section: DAC Implementation
// *****************************************************************************
// *****************************************************************************

void ${DAC_INSTANCE_NAME}_Initialize (void)
{
	${DAC_INSTANCE_NAME}_REGS->DAC_CTRL_DACCON = 0x${DACCON_REG_VALUE};
	${DAC_INSTANCE_NAME}_REGS->DAC_CTRL_DACCON2 = 0x${DACCON2_REG_VALUE};
}

void ${DAC_INSTANCE_NAME}_DataWrite (uint8_t data)
{
	${DAC_INSTANCE_NAME}_REGS->DAC_CTRL_DACCODE = data;
}

void ${DAC_INSTANCE_NAME}_Enable (void)
{
	${DAC_INSTANCE_NAME}_REGS->DAC_CTRL_DACCON |= DAC_CTRL_DACCON_EN_Msk;
}

void ${DAC_INSTANCE_NAME}_Disable (void)
{
	${DAC_INSTANCE_NAME}_REGS->DAC_CTRL_DACCON &= (~DAC_CTRL_DACCON_EN_Msk);
}
