/*******************************************************************************
  ${USART_INSTANCE_NAME} PLIB

  Company:
    Microchip Technology Inc.

  File Name:
    plib_${USART_INSTANCE_NAME?lower_case}.h

  Summary:
    ${USART_INSTANCE_NAME} PLIB Header File

  Description:
    None

*******************************************************************************/

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

#ifndef PLIB_${USART_INSTANCE_NAME}_LIN_H
#define PLIB_${USART_INSTANCE_NAME}_LIN_H

#include "plib_usart_lin_common.h"

// DOM-IGNORE-BEGIN
#ifdef __cplusplus  // Provide C++ Compatibility

    extern "C" {

#endif
// DOM-IGNORE-END

<#--Interface To Use-->
// *****************************************************************************
// *****************************************************************************
// Section: Interface
// *****************************************************************************
// *****************************************************************************

#define ${USART_INSTANCE_NAME}_FrequencyGet()    (uint32_t)(${USART_CLOCK_FREQ}UL)

/****************************** ${USART_INSTANCE_NAME} API *********************************/

void ${USART_INSTANCE_NAME}_Initialize( void );

USART_ERROR ${USART_INSTANCE_NAME}_ErrorGet( void );

bool ${USART_INSTANCE_NAME}_SerialSetup( USART_SERIAL_SETUP *setup, uint32_t srcClkFreq );

bool ${USART_INSTANCE_NAME}_Write( void *buffer, const size_t size );

bool ${USART_INSTANCE_NAME}_Read( void *buffer, const size_t size );

int ${USART_INSTANCE_NAME}_ReadByte( void );

void ${USART_INSTANCE_NAME}_WriteByte( int data );

bool ${USART_INSTANCE_NAME}_TransmitterIsReady( void );

bool ${USART_INSTANCE_NAME}_ReceiverIsReady( void );

bool ${USART_INSTANCE_NAME}_TransmitComplete( void );

<#if USART_MODE == "LIN_MASTER" || USART_MODE == "LIN_SLAVE">
void ${USART_INSTANCE_NAME}_LIN_NodeActionSet( USART_LIN_NACT action );

bool ${USART_INSTANCE_NAME}_LIN_IdentifierWrite( uint8_t id);

uint8_t ${USART_INSTANCE_NAME}_LIN_IdentifierRead( void);

void ${USART_INSTANCE_NAME}_LIN_ParityEnable(bool parityEnable);

void ${USART_INSTANCE_NAME}_LIN_ChecksumEnable(bool checksumEnable);

void ${USART_INSTANCE_NAME}_LIN_ChecksumTypeSet(USART_LIN_CHECKSUM_TYPE checksumType);

<#if USART_MODE == "LIN_MASTER">
void ${USART_INSTANCE_NAME}_LIN_FrameSlotEnable(bool frameSlotEnable);
</#if>

void ${USART_INSTANCE_NAME}_LIN_DataLenModeSet(USART_LIN_DATA_LEN dataLenMode);

void ${USART_INSTANCE_NAME}_LIN_ResponseDataLenSet(uint8_t len);

uint8_t ${USART_INSTANCE_NAME}_LIN_TransferComplete(void);

</#if>

// DOM-IGNORE-BEGIN
#ifdef __cplusplus  // Provide C++ Compatibility

    }

#endif

// DOM-IGNORE-END
#endif // PLIB_${USART_INSTANCE_NAME}_LIN_H
