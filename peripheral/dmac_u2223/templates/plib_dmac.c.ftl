/*******************************************************************************
  Direct Memory Access Controller (DMAC) PLIB

  Company
    Microchip Technology Inc.

  File Name
    plib_${DMA_INSTANCE_NAME?lower_case}.c

  Summary
    Source for ${DMA_INSTANCE_NAME} peripheral library interface Implementation.

  Description
    This file defines the interface to the DMAC peripheral library. This
    library provides access to and control of the DMAC controller.

  Remarks:
    None.

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

#include "plib_${DMA_INSTANCE_NAME?lower_case}.h"

// *****************************************************************************
// *****************************************************************************
// Section: Global Data
// *****************************************************************************
// *****************************************************************************

#define DMAC_CHANNELS_NUMBER        ${DMAC_HIGHEST_CHANNEL}

#define DMAC_CRC_CHANNEL_OFFSET     0x20U

/* DMAC channels object configuration structure */
typedef struct
{
    uint8_t                inUse;

    DMAC_CHANNEL_CALLBACK  callback;

    uintptr_t              context;

    uint8_t                busyStatus;

} DMAC_CH_OBJECT ;

/* Initial write back memory section for DMAC */
<#if LPRAM_PRESENT> SECTION(".lpram")</#if> static  dmac_descriptor_registers_t _write_back_section[DMAC_CHANNELS_NUMBER]    __ALIGNED(8);

/* Descriptor section for DMAC */
<#if LPRAM_PRESENT> SECTION(".lpram")</#if> static  dmac_descriptor_registers_t  descriptor_section[DMAC_CHANNELS_NUMBER]    __ALIGNED(8);

/* DMAC Channels object information structure */
DMAC_CH_OBJECT dmacChannelObj[DMAC_CHANNELS_NUMBER];

// *****************************************************************************
// *****************************************************************************
// Section: ${DMA_INSTANCE_NAME} PLib Interface Implementations
// *****************************************************************************
// *****************************************************************************

/*******************************************************************************
This function initializes the DMAC controller of the device.
********************************************************************************/

void ${DMA_INSTANCE_NAME}_Initialize( void )
{
    DMAC_CH_OBJECT *dmacChObj = (DMAC_CH_OBJECT *)&dmacChannelObj[0];
    uint16_t channel = 0;

    /* Initialize DMAC Channel objects */
    for(channel = 0; channel < DMAC_CHANNELS_NUMBER; channel++)
    {
        dmacChObj->inUse = 0;
        dmacChObj->callback = NULL;
        dmacChObj->context = 0;
        dmacChObj->busyStatus = false;

        /* Point to next channel object */
        dmacChObj += 1;
    }

    /* Update the Base address and Write Back address register */
    ${DMA_INSTANCE_NAME}_REGS->DMAC_BASEADDR = (uint32_t) descriptor_section;
    ${DMA_INSTANCE_NAME}_REGS->DMAC_WRBADDR  = (uint32_t)_write_back_section;

    /* Update the Priority Control register */
    <#if PRIORITY_REGISTER_NAME == "PRICTRL">
    <@compress single_line=true>${DMA_INSTANCE_NAME}_REGS->DMAC_PRICTRL =  DMAC_PRICTRL_LVLPRI0(${DMAC_LVLXPRIO_0}) | <#if DMAC_LVLXPRIO_0 == "1">DMAC_PRICTRL_RRLVLEN0_Msk |</#if>
                                                                           DMAC_PRICTRL_LVLPRI1(${DMAC_LVLXPRIO_1}) | <#if DMAC_LVLXPRIO_1 == "1">DMAC_PRICTRL_RRLVLEN1_Msk |</#if>
                                                                           DMAC_PRICTRL_LVLPRI2(${DMAC_LVLXPRIO_2}) | <#if DMAC_LVLXPRIO_2 == "1">DMAC_PRICTRL_RRLVLEN2_Msk |</#if>
                                                                           DMAC_PRICTRL_LVLPRI3(${DMAC_LVLXPRIO_3})<#if DMAC_LVLXPRIO_3 == "1"> | DMAC_PRICTRL_RRLVLEN3_Msk</#if>;</@compress>
    <#else>
    <@compress single_line=true>${DMA_INSTANCE_NAME}_REGS->DMAC_PRICTRL0 = DMAC_PRICTRL0_LVLPRI0(${DMAC_LVLXPRIO_0}) | <#if DMAC_LVLXPRIO_0 == "1">DMAC_PRICTRL0_RRLVLEN0_Msk |</#if>
                                                                           DMAC_PRICTRL0_LVLPRI1(${DMAC_LVLXPRIO_1}) | <#if DMAC_LVLXPRIO_1 == "1">DMAC_PRICTRL0_RRLVLEN1_Msk |</#if>
                                                                           DMAC_PRICTRL0_LVLPRI2(${DMAC_LVLXPRIO_2}) | <#if DMAC_LVLXPRIO_2 == "1">DMAC_PRICTRL0_RRLVLEN2_Msk |</#if>
                                                                           DMAC_PRICTRL0_LVLPRI3(${DMAC_LVLXPRIO_3})<#if DMAC_LVLXPRIO_3 == "1"> | DMAC_PRICTRL0_RRLVLEN3_Msk</#if>;</@compress>
    </#if>
    <#list 0..DMAC_HIGHEST_CHANNEL - 1 as i>
        <#assign DMAC_CHCTRLA_ENABLE    = "DMAC_ENABLE_CH_"           + i>
        <#assign DMAC_CHCTRLA_RUNSTDBY  = "DMAC_CHCTRLA_RUNSTDBY_CH_" + i>
        <#assign DMAC_CHCTRLB_TRIGACT   = "DMAC_CHCTRLB_TRIGACT_CH_"  + i>
        <#assign DMAC_CHCTRLB_LVL       = "DMAC_CHCTRLB_LVL_CH_"      + i>
        <#assign DMAC_BTCTRL_SRCINC     = "DMAC_BTCTRL_SRCINC_CH_"    + i>
        <#assign DMAC_BTCTRL_DSTINC     = "DMAC_BTCTRL_DSTINC_CH_"    + i>
        <#assign DMAC_BTCTRL_BEATSIZE   = "DMAC_BTCTRL_BEATSIZE_CH_"  + i>
        <#assign DMAC_TRIGSRC_PERID_VAL = "DMAC_CHCTRLB_TRIGSRC_CH_" + i + "_PERID_VAL">
        <#if i < DMA_EVSYS_CHANNEL_COUNT>
            <#assign DMAC_EVSYS_OUT = "DMAC_ENABLE_EVSYS_OUT_" + i >
            <#assign DMAC_EVSYS_IN = "DMAC_ENABLE_EVSYS_IN_" + i >
            <#assign DMAC_EVSYS_EVOSEL = "DMAC_BTCTRL_EVSYS_EVOSEL_" + i >
            <#assign DMAC_EVSYS_EVACT = "DMAC_CHCTRLB_EVACT_" + i >
        </#if>
        <#if (.vars[DMAC_CHCTRLA_ENABLE] == true)>

        <#lt>    /***************** Configure DMA channel ${i} ********************/

        <#lt>    ${DMA_INSTANCE_NAME}_REGS->DMAC_CHID = ${i};

                <#if .vars[DMAC_CHCTRLA_RUNSTDBY]?? && .vars[DMAC_CHCTRLA_RUNSTDBY] == true>
                    <#lt>    ${DMA_INSTANCE_NAME}_REGS->DMAC_CHCTRLA |= DMAC_CHCTRLA_RUNSTDBY_Msk;

                </#if>
        <#lt>    <@compress single_line=true>${DMA_INSTANCE_NAME}_REGS->DMAC_CHCTRLB = DMAC_CHCTRLB_TRIGACT(${.vars[DMAC_CHCTRLB_TRIGACT]}) |
                                                                                       DMAC_CHCTRLB_TRIGSRC(${.vars[DMAC_TRIGSRC_PERID_VAL]}) |
                                                                                       DMAC_CHCTRLB_LVL(${.vars[DMAC_CHCTRLB_LVL]})
                                                                                       <#if i < DMA_EVSYS_CHANNEL_COUNT>
                                                                                       ${(.vars[DMAC_EVSYS_IN])?then('| DMAC_CHCTRLB_EVACT(${.vars[DMAC_EVSYS_EVACT]}) | DMAC_CHCTRLB_EVIE_Msk','')}
                                                                                       ${(.vars[DMAC_EVSYS_OUT])?then('| DMAC_CHCTRLB_EVOE_Msk','')}
                                                                                       </#if>
                                                                                       ;</@compress>

        <#lt>    <@compress single_line=true>descriptor_section[${i}].DMAC_BTCTRL = DMAC_BTCTRL_BLOCKACT_INT |
                                                                                    DMAC_BTCTRL_BEATSIZE_${.vars[DMAC_BTCTRL_BEATSIZE]} |
                                                                                    DMAC_BTCTRL_VALID_Msk
                                                                                    ${(.vars[DMAC_BTCTRL_SRCINC] == "INCREMENTED_AM")?then('| DMAC_BTCTRL_SRCINC_Msk','')}
                                                                                    ${(.vars[DMAC_BTCTRL_DSTINC] == "INCREMENTED_AM")?then('| DMAC_BTCTRL_DSTINC_Msk','')}
                                                                                    <#if i < DMA_EVSYS_CHANNEL_COUNT>
                                                                                    ${(.vars[DMAC_EVSYS_OUT])?then('| DMAC_BTCTRL_EVOSEL(${.vars[DMAC_EVSYS_EVOSEL]})','')}
                                                                                    </#if>
                                                                                    ;</@compress>

        <#lt>    dmacChannelObj[${i}].inUse = 1;

        <#lt>    ${DMA_INSTANCE_NAME}_REGS->DMAC_CHINTENSET = (DMAC_CHINTENSET_TERR_Msk | DMAC_CHINTENSET_TCMPL_Msk);
        </#if>
    </#list>

    /* Enable the DMAC module & Priority Level x Enable */
    ${DMA_INSTANCE_NAME}_REGS->DMAC_CTRL = DMAC_CTRL_DMAENABLE_Msk | DMAC_CTRL_LVLEN0_Msk | DMAC_CTRL_LVLEN1_Msk | DMAC_CTRL_LVLEN2_Msk | DMAC_CTRL_LVLEN3_Msk;
}

/*******************************************************************************
    This function schedules a DMA transfer on the specified DMA channel.
********************************************************************************/

bool ${DMA_INSTANCE_NAME}_ChannelTransfer( DMAC_CHANNEL channel, const void *srcAddr, const void *destAddr, size_t blockSize )
{
    uint8_t beat_size = 0;
    uint8_t channelId = 0;
    bool returnStatus = false;

    if (dmacChannelObj[channel].busyStatus == false)
    {
        /* Get a pointer to the module hardware instance */
        dmac_descriptor_registers_t *const dmacDescReg = &descriptor_section[channel];

        dmacChannelObj[channel].busyStatus = true;

        /* Set source address */
        if (dmacDescReg->DMAC_BTCTRL & DMAC_BTCTRL_SRCINC_Msk)
        {
            dmacDescReg->DMAC_SRCADDR = (uint32_t) ((intptr_t)srcAddr + blockSize);
        }
        else
        {
            dmacDescReg->DMAC_SRCADDR = (uint32_t) (srcAddr);
        }

        /* Set destination address */
        if (dmacDescReg->DMAC_BTCTRL & DMAC_BTCTRL_DSTINC_Msk)
        {
            dmacDescReg->DMAC_DSTADDR = (uint32_t) ((intptr_t)destAddr + blockSize);
        }
        else
        {
            dmacDescReg->DMAC_DSTADDR = (uint32_t) (destAddr);
        }

        /* Calculate the beat size and then set the BTCNT value */
        beat_size = (dmacDescReg->DMAC_BTCTRL & DMAC_BTCTRL_BEATSIZE_Msk) >> DMAC_BTCTRL_BEATSIZE_Pos;

        /* Set Block Transfer Count */
        dmacDescReg->DMAC_BTCNT = blockSize / (1 << beat_size);

        /* Save channel ID */
        channelId = (uint8_t)${DMA_INSTANCE_NAME}_REGS->DMAC_CHID;

        /* Set the DMA channel */
        ${DMA_INSTANCE_NAME}_REGS->DMAC_CHID = channel;

        /* Enable the channel */
        ${DMA_INSTANCE_NAME}_REGS->DMAC_CHCTRLA |= DMAC_CHCTRLA_ENABLE_Msk;

        /* Verify if Trigger source is Software Trigger */
        if ((((${DMA_INSTANCE_NAME}_REGS->DMAC_CHCTRLB & DMAC_CHCTRLB_TRIGSRC_Msk) >> DMAC_CHCTRLB_TRIGSRC_Pos) == 0x00)
                                        && ((${DMA_INSTANCE_NAME}_REGS->DMAC_CHCTRLB & DMAC_CHCTRLB_EVIE_Msk) != DMAC_CHCTRLB_EVIE_Msk))
        {
            /* Trigger the DMA transfer */
            ${DMA_INSTANCE_NAME}_REGS->DMAC_SWTRIGCTRL |= (1 << channel);
        }

        /* Restore channel ID */
        ${DMA_INSTANCE_NAME}_REGS->DMAC_CHID = channelId;

        returnStatus = true;
    }

    return returnStatus;
}

/*******************************************************************************
    This function returns the status of the channel.
********************************************************************************/

bool ${DMA_INSTANCE_NAME}_ChannelIsBusy ( DMAC_CHANNEL channel )
{
    return (bool)dmacChannelObj[channel].busyStatus;
}

/*******************************************************************************
    This function disables the specified DMAC channel.
********************************************************************************/

void ${DMA_INSTANCE_NAME}_ChannelDisable ( DMAC_CHANNEL channel )
{
    uint8_t channelId = 0;

    /* Save channel ID */
    channelId = (uint8_t)${DMA_INSTANCE_NAME}_REGS->DMAC_CHID;

    /* Set the DMA Channel ID */
    ${DMA_INSTANCE_NAME}_REGS->DMAC_CHID = channel;

    /* Disable the DMA channel */
    ${DMA_INSTANCE_NAME}_REGS->DMAC_CHCTRLA &= (~DMAC_CHCTRLA_ENABLE_Msk);

    while((${DMA_INSTANCE_NAME}_REGS->DMAC_CHCTRLA & DMAC_CHCTRLA_ENABLE_Msk) != 0);

    dmacChannelObj[channel].busyStatus = false;

    /* Restore channel ID */
    ${DMA_INSTANCE_NAME}_REGS->DMAC_CHID = channelId;
}

uint16_t ${DMA_INSTANCE_NAME}_ChannelGetTransferredCount( DMAC_CHANNEL channel )
{
    return(descriptor_section[channel].DMAC_BTCNT - _write_back_section[channel].DMAC_BTCNT);
}

<#if DMAC_LL_ENABLE = true>
void ${DMA_INSTANCE_NAME}_LinkedListDescriptorSetup (dmac_descriptor_registers_t* currentDescriptor,
                                                    DMAC_CHANNEL_CONFIG setting,
                                                    const void *srcAddr,
                                                    const void *destAddr,
                                                    size_t blockSize,
                                                    dmac_descriptor_registers_t* nextDescriptor)
{
    uint8_t beat_size = 0;
  
    currentDescriptor->DMAC_BTCTRL = setting;
  
    // Set source address
    if (currentDescriptor->DMAC_BTCTRL & DMAC_BTCTRL_SRCINC_Msk)
    {
      currentDescriptor->DMAC_SRCADDR = (uint32_t) ((intptr_t)srcAddr + blockSize);
    }
    else
    {
      currentDescriptor->DMAC_SRCADDR = (uint32_t) (srcAddr);
    }
  
    // Set destination address
    if (currentDescriptor->DMAC_BTCTRL & DMAC_BTCTRL_DSTINC_Msk)
    {
      currentDescriptor->DMAC_DSTADDR = (uint32_t) ((intptr_t)destAddr + blockSize);
    }
    else
    {
      currentDescriptor->DMAC_DSTADDR = (uint32_t) (destAddr);
    }
  
    // Calculate the beat size and then set the BTCNT value
    beat_size = (currentDescriptor->DMAC_BTCTRL & DMAC_BTCTRL_BEATSIZE_Msk) >> DMAC_BTCTRL_BEATSIZE_Pos;
    currentDescriptor->DMAC_BTCNT = blockSize / (1 << beat_size);
  
    currentDescriptor->DMAC_DESCADDR = (uint32_t) nextDescriptor;
}                                                    
/*******************************************************************************
    This function submit a list of DMA transfers.
********************************************************************************/
bool ${DMA_INSTANCE_NAME}_ChannelLinkedListTransfer (DMAC_CHANNEL channel, dmac_descriptor_registers_t* channelDesc)
{
    bool returnStatus = false;
    uint8_t channelId = 0;

    if (dmacChannelObj[channel].busyStatus == false)
    {
        /* Save channel ID */
        channelId = (uint8_t)${DMA_INSTANCE_NAME}_REGS->DMAC_CHID;

        /* Set the DMA channel */
        ${DMA_INSTANCE_NAME}_REGS->DMAC_CHID = channel;

        dmacChannelObj[channel].busyStatus = true;

        memcpy(&descriptor_section[channel], channelDesc, sizeof(dmac_descriptor_registers_t));

        /* Enable the channel */
        ${DMA_INSTANCE_NAME}_REGS->DMAC_CHCTRLA |= DMAC_CHCTRLA_ENABLE_Msk;

        /* Verify if Trigger source is Software Trigger */
        if (((${DMA_INSTANCE_NAME}_REGS->DMAC_CHCTRLB & DMAC_CHCTRLB_TRIGSRC_Msk) >> DMAC_CHCTRLB_TRIGSRC_Pos) == 0x00)
        {
            /* Trigger the DMA transfer */
            ${DMA_INSTANCE_NAME}_REGS->DMAC_SWTRIGCTRL |= (1 << channel);
        }

        /* Restore channel ID */
        ${DMA_INSTANCE_NAME}_REGS->DMAC_CHID = channelId;

        returnStatus = true;
    }

    return returnStatus;
}
</#if>

/*******************************************************************************
    This function function allows a DMAC PLIB client to set an event handler.
********************************************************************************/

void ${DMA_INSTANCE_NAME}_ChannelCallbackRegister( DMAC_CHANNEL channel, const DMAC_CHANNEL_CALLBACK callback, const uintptr_t context )
{
    dmacChannelObj[channel].callback = callback;

    dmacChannelObj[channel].context  = context;
}

/*******************************************************************************
    This function returns the current channel settings for the specified DMAC Channel
********************************************************************************/

DMAC_CHANNEL_CONFIG ${DMA_INSTANCE_NAME}_ChannelSettingsGet (DMAC_CHANNEL channel)
{
    /* Get a pointer to the module hardware instance */
    dmac_descriptor_registers_t *const dmacDescReg = &descriptor_section[0];

    return (dmacDescReg[channel].DMAC_BTCTRL);
}

/*******************************************************************************
    This function changes the current settings of the specified DMAC channel.
********************************************************************************/

bool ${DMA_INSTANCE_NAME}_ChannelSettingsSet (DMAC_CHANNEL channel, DMAC_CHANNEL_CONFIG setting)
{
    uint8_t channelId = 0;

    /* Get a pointer to the module hardware instance */
    dmac_descriptor_registers_t *const dmacDescReg = &descriptor_section[0];

    /* Save channel ID */
    channelId = (uint8_t)${DMA_INSTANCE_NAME}_REGS->DMAC_CHID;

    /* Set the DMA Channel ID */
    ${DMA_INSTANCE_NAME}_REGS->DMAC_CHID = channel;

    /* Disable the DMA channel */
    ${DMA_INSTANCE_NAME}_REGS->DMAC_CHCTRLA &= (~DMAC_CHCTRLA_ENABLE_Msk);

    /* Wait for channel to be disabled */
    while((${DMA_INSTANCE_NAME}_REGS->DMAC_CHCTRLA & DMAC_CHCTRLA_ENABLE_Msk) != 0);

    /* Set the new settings */
    dmacDescReg[channel].DMAC_BTCTRL = setting;

    /* Restore channel ID */
    ${DMA_INSTANCE_NAME}_REGS->DMAC_CHID = channelId;

    return true;
}

/*******************************************************************************
    This function Disables the CRC engine and clears the CRC Control register
********************************************************************************/
void ${DMA_INSTANCE_NAME}_CRCDisable( void )
{
    ${DMA_INSTANCE_NAME}_REGS->DMAC_CTRL &= ~DMAC_CTRL_CRCENABLE_Msk;

    ${DMA_INSTANCE_NAME}_REGS->DMAC_CRCCTRL = DMAC_CRCCTRL_RESETVALUE;
}

/*******************************************************************************
    This function sets the CRC Engine to use DMAC channel for calculating CRC.

    This Function has to be called before submitting DMA transfer request for
    the channel to calculate CRC
********************************************************************************/

void ${DMA_INSTANCE_NAME}_ChannelCRCSetup(DMAC_CHANNEL channel, DMAC_CRC_SETUP CRCSetup)
{
    /* Disable CRC Engine and clear the CRC Control register before configuring */
    ${DMA_INSTANCE_NAME}_CRCDisable();

    ${DMA_INSTANCE_NAME}_REGS->DMAC_CRCCHKSUM = CRCSetup.seed;

    /* Setup the CRC engine to use DMA Channel */
    ${DMA_INSTANCE_NAME}_REGS->DMAC_CRCCTRL = (DMAC_CRCCTRL_CRCPOLY(CRCSetup.polynomial_type) | DMAC_CRCCTRL_CRCSRC((DMAC_CRC_CHANNEL_OFFSET + channel)));

    ${DMA_INSTANCE_NAME}_REGS->DMAC_CTRL |= DMAC_CTRL_CRCENABLE_Msk;
}

/*******************************************************************************
    This function returns the Caclculated CRC Value.
********************************************************************************/

uint32_t ${DMA_INSTANCE_NAME}_CRCRead( void )
{
    return (${DMA_INSTANCE_NAME}_REGS->DMAC_CRCCHKSUM);
}

/*******************************************************************************
    This function sets the CRC Engine in IO mode to get the data using the CPU
    which will be written in CRCDATAIN register. It internally calculates the
    Beat Size to be used based on the buffer length.

    This function returns the final CRC value once the computation is done
********************************************************************************/
uint32_t ${DMA_INSTANCE_NAME}_CRCCalculate(void *buffer, uint32_t length, DMAC_CRC_SETUP CRCSetup)
{
    uint8_t beatSize    = DMAC_CRC_BEAT_SIZE_BYTE;
    uint32_t counter    = 0;
    uint8_t *buffer_8   = (uint8_t *)buffer;
    uint16_t *buffer_16 = (uint16_t *)buffer;
    uint32_t *buffer_32 = (uint32_t *)buffer;

    /* Calculate the beatsize to be used basd on buffer length */
    if ((length & 0x3U) == 0)
    {
        beatSize = DMAC_CRC_BEAT_SIZE_WORD;
        length = length >> 0x2U;
    }
    else if ((length & 0x1U) == 0)
    {
        beatSize = DMAC_CRC_BEAT_SIZE_HWORD;
        length = length >> 0x1U;
    }

    /* Disable CRC Engine and clear the CRC Control register before configuring */
    ${DMA_INSTANCE_NAME}_CRCDisable();

    ${DMA_INSTANCE_NAME}_REGS->DMAC_CRCCHKSUM = CRCSetup.seed;

    /* Setup the CRC engine to use IO Mode */
    ${DMA_INSTANCE_NAME}_REGS->DMAC_CRCCTRL = (DMAC_CRCCTRL_CRCPOLY(CRCSetup.polynomial_type) | DMAC_CRCCTRL_CRCBEATSIZE(beatSize) | DMAC_CRCCTRL_CRCSRC_IO );

    ${DMA_INSTANCE_NAME}_REGS->DMAC_CTRL |= DMAC_CTRL_CRCENABLE_Msk;

    /* Start the CRC calculation by writing the buffer into CRCDATAIN register based
     * on the beat size configured
     */
    for (counter = 0; counter < length; counter++)
    {
        if (beatSize == DMAC_CRC_BEAT_SIZE_BYTE)
        {
            ${DMA_INSTANCE_NAME}_REGS->DMAC_CRCDATAIN = buffer_8[counter];
        }
        else if (beatSize == DMAC_CRC_BEAT_SIZE_HWORD)
        {
            ${DMA_INSTANCE_NAME}_REGS->DMAC_CRCDATAIN = buffer_16[counter];
        }
        else if (beatSize == DMAC_CRC_BEAT_SIZE_WORD)
        {
            ${DMA_INSTANCE_NAME}_REGS->DMAC_CRCDATAIN = buffer_32[counter];
        }

        /* Wait until CRC Calculation is completed for the current data in CRCDATAIN */
        while (!(${DMA_INSTANCE_NAME}_REGS->DMAC_CRCSTATUS & DMAC_CRCSTATUS_CRCBUSY_Msk))
        {
            ;
        }

        /* Clear the busy bit */
        ${DMA_INSTANCE_NAME}_REGS->DMAC_CRCSTATUS = DMAC_CRCSTATUS_CRCBUSY_Msk; 
    }

    /* Return the final CRC calculated for the entire buffer */
    return (${DMA_INSTANCE_NAME}_REGS->DMAC_CRCCHKSUM);
}

/*******************************************************************************
    This function handles the DMA interrupt events.
*/
<#if DMAC_MULTIVECTOR_SUPPORTED??>
<#list 0..3 as x>
void ${DMA_INSTANCE_NAME}_${x}_InterruptHandler( void )
{
    DMAC_CH_OBJECT  *dmacChObj = NULL;
    uint8_t channel = 0;
    uint8_t channelId = 0;
    volatile uint32_t chanIntFlagStatus = 0;
    DMAC_TRANSFER_EVENT event = DMAC_TRANSFER_EVENT_ERROR;

    /* Get active channel number */
    channel = ${x};

    dmacChObj = (DMAC_CH_OBJECT *)&dmacChannelObj[channel];

    /* Save channel ID */
    channelId = (uint8_t)${DMA_INSTANCE_NAME}_REGS->DMAC_CHID;

    /* Update the DMAC channel ID */
    ${DMA_INSTANCE_NAME}_REGS->DMAC_CHID = channel;

    /* Get the DMAC channel interrupt status */
    chanIntFlagStatus = ${DMA_INSTANCE_NAME}_REGS->DMAC_CHINTFLAG;

    /* Verify if DMAC Channel Transfer complete flag is set */
    if (chanIntFlagStatus & DMAC_CHINTENCLR_TCMPL_Msk)
    {
        /* Clear the transfer complete flag */
        ${DMA_INSTANCE_NAME}_REGS->DMAC_CHINTFLAG = DMAC_CHINTENCLR_TCMPL_Msk;

        event = DMAC_TRANSFER_EVENT_COMPLETE;

        dmacChObj->busyStatus = false;
    }

    /* Verify if DMAC Channel Error flag is set */
    if (chanIntFlagStatus & DMAC_CHINTENCLR_TERR_Msk)
    {
        /* Clear transfer error flag */
        ${DMA_INSTANCE_NAME}_REGS->DMAC_CHINTFLAG = DMAC_CHINTENCLR_TERR_Msk;

        event = DMAC_TRANSFER_EVENT_ERROR;

        dmacChObj->busyStatus = false;
    }

    /* Execute the callback function */
    if (dmacChObj->callback != NULL)
    {
        dmacChObj->callback (event, dmacChObj->context);
    }

    /* Restore channel ID */
    ${DMA_INSTANCE_NAME}_REGS->DMAC_CHID = channelId;
}
</#list>

void ${DMA_INSTANCE_NAME}_OTHER_InterruptHandler( void )
{
    DMAC_CH_OBJECT  *dmacChObj = NULL;
    uint8_t channel = 0;
    uint8_t channelId = 0;
    volatile uint32_t chanIntFlagStatus = 0;
    DMAC_TRANSFER_EVENT event = DMAC_TRANSFER_EVENT_ERROR;

    /* Get active channel number */
    channel = ${DMA_INSTANCE_NAME}_REGS->DMAC_INTPEND & DMAC_INTPEND_ID_Msk;

    dmacChObj = (DMAC_CH_OBJECT *)&dmacChannelObj[channel];

    /* Save channel ID */
    channelId = (uint8_t)${DMA_INSTANCE_NAME}_REGS->DMAC_CHID;

    /* Update the DMAC channel ID */
    ${DMA_INSTANCE_NAME}_REGS->DMAC_CHID = channel;

    /* Get the DMAC channel interrupt status */
    chanIntFlagStatus = ${DMA_INSTANCE_NAME}_REGS->DMAC_CHINTFLAG;

    /* Verify if DMAC Channel Transfer complete flag is set */
    if (chanIntFlagStatus & DMAC_CHINTENCLR_TCMPL_Msk)
    {
        /* Clear the transfer complete flag */
        ${DMA_INSTANCE_NAME}_REGS->DMAC_CHINTFLAG = DMAC_CHINTENCLR_TCMPL_Msk;

        event = DMAC_TRANSFER_EVENT_COMPLETE;

        dmacChObj->busyStatus = false;
    }

    /* Verify if DMAC Channel Error flag is set */
    if (chanIntFlagStatus & DMAC_CHINTENCLR_TERR_Msk)
    {
        /* Clear transfer error flag */
        ${DMA_INSTANCE_NAME}_REGS->DMAC_CHINTFLAG = DMAC_CHINTENCLR_TERR_Msk;

        event = DMAC_TRANSFER_EVENT_ERROR;

        dmacChObj->busyStatus = false;
    }

    /* Execute the callback function */
    if (dmacChObj->callback != NULL)
    {
        dmacChObj->callback (event, dmacChObj->context);
    }

    /* Restore channel ID */
    ${DMA_INSTANCE_NAME}_REGS->DMAC_CHID = channelId;
}
<#else>
void ${DMA_INSTANCE_NAME}_InterruptHandler( void )
{
    DMAC_CH_OBJECT  *dmacChObj = NULL;
    uint8_t channel = 0;
    uint8_t channelId = 0;
    volatile uint32_t chanIntFlagStatus = 0;
    DMAC_TRANSFER_EVENT event = DMAC_TRANSFER_EVENT_ERROR;

    /* Get active channel number */
    channel = ${DMA_INSTANCE_NAME}_REGS->DMAC_INTPEND & DMAC_INTPEND_ID_Msk;

    dmacChObj = (DMAC_CH_OBJECT *)&dmacChannelObj[channel];

    /* Save channel ID */
    channelId = (uint8_t)${DMA_INSTANCE_NAME}_REGS->DMAC_CHID;

    /* Update the DMAC channel ID */
    ${DMA_INSTANCE_NAME}_REGS->DMAC_CHID = channel;

    /* Get the DMAC channel interrupt status */
    chanIntFlagStatus = ${DMA_INSTANCE_NAME}_REGS->DMAC_CHINTFLAG;

    /* Verify if DMAC Channel Transfer complete flag is set */
    if (chanIntFlagStatus & DMAC_CHINTENCLR_TCMPL_Msk)
    {
        /* Clear the transfer complete flag */
        ${DMA_INSTANCE_NAME}_REGS->DMAC_CHINTFLAG = DMAC_CHINTENCLR_TCMPL_Msk;

        event = DMAC_TRANSFER_EVENT_COMPLETE;

        dmacChObj->busyStatus = false;
    }

    /* Verify if DMAC Channel Error flag is set */
    if (chanIntFlagStatus & DMAC_CHINTENCLR_TERR_Msk)
    {
        /* Clear transfer error flag */
        ${DMA_INSTANCE_NAME}_REGS->DMAC_CHINTFLAG = DMAC_CHINTENCLR_TERR_Msk;

        event = DMAC_TRANSFER_EVENT_ERROR;

        dmacChObj->busyStatus = false;
    }

    /* Execute the callback function */
    if (dmacChObj->callback != NULL)
    {
        dmacChObj->callback (event, dmacChObj->context);
    }

    /* Restore channel ID */
    ${DMA_INSTANCE_NAME}_REGS->DMAC_CHID = channelId;
}
</#if>