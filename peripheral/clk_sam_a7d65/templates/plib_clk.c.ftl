/*******************************************************************************
* Copyright (C) 2024 Microchip Technology Inc. and its subsidiaries.
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
<#compress>
<#if USE_BOOTLOADER_GENERATORS?? && (USE_BOOTLOADER_GENERATORS == false)>
<#assign PLL_LIST = ["CPUPLL", "SYSPLL", "DDRPLL", "GPUPLL", "BAUDPLL", "AUDIOPLL", "ETHPLL", "LVDSPLL"]>
<#else>
<#assign PLL_LIST = ["AUDIOPLL", "ETHPLL", "LVDSPLL"]>
</#if>
<#if MAINCK_FREQUENCY lte 16000000>
<#assign XTALF = "F16M">
<#elseif MAINCK_FREQUENCY lte 20000000>
<#assign XTALF = "F20M">
<#elseif MAINCK_FREQUENCY lte 24000000>
<#assign XTALF = "F24M">
<#else>
<#assign XTALF = "F32M">
</#if>
</#compress>


#include <stdbool.h>
#include "device.h"
#include "plib_clk.h"

#define PLL_ID_CPUPLL           0U
#define PLL_ID_SYSPLL           1U
#define PLL_ID_DDRPLL           2U
#define PLL_ID_GPUPLL           3U
#define PLL_ID_BAUDPLL          4U
#define PLL_ID_AUDIOPLL         5U
#define PLL_ID_ETHPLL           6U
#define PLL_ID_LVDSPLL          7U
#define PLL_ID_USBPLL           8U
#define PLL_UPDT_STUPTIM_VAL    0x3FU
#define PLL_ACR_RECOMMENDED     0x00070010U

<#if SYSTEM_COUNTER_ENABLE>
#define APB9_BASE 0xE8800000U
#define TIMESTAMP_OFFSET 0x43000U
#define PSELCTRL_REGS ((pselctrl_registers_t*)(APB9_BASE + TIMESTAMP_OFFSET))

#define CNTCR_EN_Pos            0U
#define CNTCR_EN_Msk            (1U << CNTCR_EN_Pos)

#define SYSTEM_COUNTER_FREQUENCY ${MAINCK_FREQUENCY}U
</#if>

typedef struct pmc_pll_cfg {
    uint32_t mul;
    uint32_t divpll;
    bool eniopllck;
    uint32_t divio;
    uint32_t count;
    uint32_t fracr;
    uint32_t acr;
    bool ss;
    uint32_t step;
    uint32_t nstep;
}pmc_pll_cfg_t;

<#if SYSTEM_COUNTER_ENABLE>

typedef struct
{
    __IO   uint32_t CNTCR;
    __O    uint32_t CNTSR;
    __IO   uint32_t CNTCVL;
    __IO   uint32_t CNTCVU;
    __I    uint8_t  Reserved[0x14];
    __IO   uint32_t CNTFID0;
}pselctrl_registers_t;
</#if>

<#assign NEED_PLL_INIT = false>
<#list PLL_LIST as PLL_NAME>
<#if .vars["CLK_" + PLL_NAME + "_EN"]>
<#assign NEED_PLL_INIT = true>
static pmc_pll_cfg_t ${PLL_NAME?lower_case}_cfg = {
    .mul = ${.vars["CLK_" + PLL_NAME + "_MUL"]}U,
    .divpll = ${.vars["CLK_" + PLL_NAME + "_DIVPMC"]}U,
<#if .vars["CLK_" + PLL_NAME + "_ENIOPLLCK"]?? && .vars["CLK_" + PLL_NAME + "_ENIOPLLCK"]>
    .eniopllck = true,
    .divio = ${.vars["CLK_" + PLL_NAME + "_DIVIO"]}U,
<#else>
    .eniopllck = false,
    .divio = 0U,
</#if>
    .count = PLL_UPDT_STUPTIM_VAL,
    .fracr = ${.vars["CLK_" + PLL_NAME + "_FRACR"]}U,
    .acr = PLL_ACR_RECOMMENDED,
    .ss = ${.vars["CLK_" + PLL_NAME + "_SS"]?string("true", "false")},
    .step = ${.vars["CLK_" + PLL_NAME + "_SS_STEP"]}U,
    .nstep = ${.vars["CLK_" + PLL_NAME + "_SS_NSTEP"]}U
};

</#if>
</#list>

<#if NEED_PLL_INIT>
/*********************************************************************************
Initialize PLL
*********************************************************************************/
static void initPLL(uint32_t pll_id, pmc_pll_cfg_t *pll_cfg)
{
    /* STEP 1: Define the ID and startup time by configuring the fields PMC_PLL_UPDT.ID and PMC_PLL_UPDT.STUPTIM.
       Set PMC_PLL_UPDT.UPDATE to 0 */
    uint32_t reg = PMC_REGS->PMC_PLL_UPDT & ~(PMC_PLL_UPDT_UPDATE_Msk);
    reg |= (PMC_PLL_UPDT_ID(pll_id)  | PMC_PLL_UPDT_STUPTIM(pll_cfg->count));
    PMC_REGS->PMC_PLL_UPDT = reg;

    /* STEP 2: Configure PMC_PLL_ACR.LOOP_FILTER */
    PMC_REGS->PMC_PLL_ACR = pll_cfg->acr;

    /* STEP 3: Define the MUL and FRACR to be applied to PLL(n) in PMC_PLL_CTRL1 */
    PMC_REGS->PMC_PLL_CTRL1 = PMC_PLL_CTRL1_MUL(pll_cfg->mul) | PMC_PLL_CTRL1_FRACR(pll_cfg->fracr);

    /* STEP 4: Set PMC_PLL_UPDT.UPDATE to 1 */
    PMC_REGS->PMC_PLL_UPDT |= PMC_PLL_UPDT_UPDATE_Msk;

    /* STEP 5: In PMC_PLL_CTRL0, write 1 to ENLOCK and to ENPLL and configure DIVPMC, DIVIO, ENPLLCK and ENIOPLLCK */
    reg = PMC_REGS->PMC_PLL_CTRL0 & ~(PMC_PLL_CTRL0_Msk);
    reg |= (PMC_PLL_CTRL0_ENPLL_Msk | PMC_PLL_CTRL0_ENPLLCK_Msk | PMC_PLL_CTRL0_ENLOCK_Msk | PMC_PLL_CTRL0_DIVPMC(pll_cfg->divpll));
    if (pll_cfg->eniopllck)
    {
        reg |= (PMC_PLL_CTRL0_ENIOPLLCK_Msk | PMC_PLL_CTRL0_DIVIO(pll_cfg->divio));
    }
    PMC_REGS->PMC_PLL_CTRL0 = reg;

    /* STEP 6: Set PMC_PLL_UPDT.UPDATE to 1 */
    PMC_REGS->PMC_PLL_UPDT |= PMC_PLL_UPDT_UPDATE_Msk;

    /* STEP 7: Wait for the lock bit to rise by polling the PMC_PLL_ISR0 */
    uint32_t pll_lock_mask = 1UL << pll_id;
    while ((PMC_REGS->PMC_PLL_ISR0 & pll_lock_mask) != pll_lock_mask)
    {
        /* Wait for PLL lock to rise */
    }
    /* Setup spread spectrum, if is enabled */
    if (pll_cfg->ss)
    {
        reg = PMC_REGS->PMC_PLL_SSR & ~(PMC_PLL_SSR_Msk);
        reg |= (PMC_PLL_SSR_ENSPREAD_Msk | PMC_PLL_SSR_STEP(pll_cfg->step) | PMC_PLL_SSR_NSTEP(pll_cfg->nstep));
        PMC_REGS->PMC_PLL_SSR = reg;
    }
}


</#if>
<#if CLK_USBPLL_EN>
<#-- If USBPLL is initilazed as part of the generator code, it will be done before CPU clock is updated to MCC configuration -->
<#-- In such case delay should be calculated with ROM code CPU frequency which is set to 570 MHz (Datasheet Section 19.4) -->
<#if USE_BOOTLOADER_GENERATORS == false>
    <#assign DELAY_SRC_CLK_FREQUENCY = 570000000>
<#-- If USBPLL is initialized after CPU clock is setup, then use whatever cpu clock is configured in MCC -->
<#else>
    <#assign DELAY_SRC_CLK_FREQUENCY = CPU_CLOCK_FREQUENCY>
</#if>

/*********************************************************************************
Generate Software delay (in multiples of microsecond units)
*********************************************************************************/
static void swDelayUs(uint32_t delay)
{
    uint32_t i, count;
    /* delay * (CPU_FREQ/1000000) / 6 */
    count = delay *  (${DELAY_SRC_CLK_FREQUENCY}U/1000000U)/6U;
    for (i = 0; i < count; i++)
    {
        /* 6 CPU cycles per iteration */
        __NOP();
    }
}

/*********************************************************************************
Initialize USBPLL
*********************************************************************************/
static void initUSBPLLCLK(void)
{
    /* STEP 1: PMC_PLL_UPDT to target USBPLL, startup time of 150us and update disabled */
    PMC_REGS->PMC_PLL_UPDT = PMC_PLL_UPDT_STUPTIM(0x6U) |\
                             PMC_PLL_UPDT_UPDATE(0x0U) |\
                             PMC_PLL_UPDT_ID(PLL_ID_USBPLL);

    /* STEP 2: Set the Analog controls to the values recommended by data sheet */
    PMC_REGS->PMC_PLL_ACR = PMC_PLL_ACR_LOOP_FILTER(0x1BU) |\
                            PMC_PLL_ACR_LOCK_THR(0x4U) |\
                            PMC_PLL_ACR_CONTROL(0x10U);

    /* STEP 3: Set loop paramaters for the fractional PLL */
    PMC_REGS->PMC_PLL_CTRL1 = PMC_PLL_CTRL1_MUL(${CLK_USBPLL_MUL}U) |\
                              PMC_PLL_CTRL1_FRACR(${CLK_USBPLL_FRACR}U);

    /* STEP 4: Enable UTMI Bandgap */
    PMC_REGS->PMC_PLL_ACR |= PMC_PLL_ACR_UTMIBG_Msk;

    /* STEP 5: Wait 10 us */
    swDelayUs(10);

    /* STEP 6: Enable UTMI Internal Regulator */
    PMC_REGS->PMC_PLL_ACR |= PMC_PLL_ACR_UTMIVR_Msk;

    /* STEP 7: Wait 10 us */
    swDelayUs(10);

    /* STEP 8: Update the PLL controls */
    PMC_REGS->PMC_PLL_UPDT |= PMC_PLL_UPDT_UPDATE_Msk;

    /* STEP 9: Enable USBPLL, lock and PMC clock from USBPLL */
    PMC_REGS->PMC_PLL_CTRL0 = PMC_PLL_CTRL0_ENLOCK_Msk |\
                              PMC_PLL_CTRL0_ENPLL_Msk |\
                              PMC_PLL_CTRL0_ENPLLCK_Msk;

    /* STEP 10: Wait for the lock bit to rise by polling the PMC_PLL_ISR0 */
    uint32_t pll_lock_mask = 1UL << PLL_ID_USBPLL;
    while ((PMC_REGS->PMC_PLL_ISR0 & pll_lock_mask) != pll_lock_mask)
    {
        /* Wait for PLL lock to rise */
    }
}
</#if>
/*********************************************************************************
Initialize Programmable clocks
*********************************************************************************/
static void initProgrammableClocks(void)
{
    PMC_REGS->PMC_SCDR = PMC_SCDR_PCK_Msk;
<#list 0..CLK_NUM_PCKS - 1 as i>
<#if .vars["CLK_PCK"+i+"_EN"]>
<#assign css = .vars["CLK_PCK"+i+"_CSS"]>
<#assign pres = .vars["CLK_PCK"+i+"_PRES"]>
    PMC_REGS->PMC_PCK[${i}] = PMC_PCK_CSS_${css} |\
                                PMC_PCK_PRES(${pres}UL);
    PMC_REGS->PMC_SCER |= PMC_SCDR_PCK${i}_Msk;
    while ((PMC_REGS->PMC_SR & PMC_SR_PCKRDY${i}_Msk) != PMC_SR_PCKRDY${i}_Msk)
    {
        /* Wait for PCKRDY */
    }
</#if>
</#list>
}

/*********************************************************************************
Initialize Peripheral clocks
*********************************************************************************/
static void initPeripheralClocks(void)
{
    const uint8_t EOL_MARKER = ((uint8_t)ID_PERIPH_MAX + 1U);
    struct {
        uint8_t id;
        uint8_t clken;
        uint8_t gclken;
        uint8_t css;
        uint8_t divs;
    } periphList[] =
    {
        <#list 0..CLK_MAX_PERIPHERAL_ID as i>
            <#if .vars["CLK_ID_NAME_"+i]?has_content>
                <#assign name = .vars["CLK_ID_NAME_"+ i]>
                <#if .vars[name + "_CLOCK_ENABLE"]?has_content && .vars[name + "_CLOCK_ENABLE"]>
                <#assign clken = true>
                <#else>
                <#assign clken = false>
                </#if>
                <#if name?matches("TC[0-9]_CHANNEL0")>
                    <#assign gclk_name = name[0..2]>
                <#else>
                    <#assign gclk_name = name>
                </#if>
                <#if .vars["CLK_" + gclk_name + "_GCLKEN"]?has_content && .vars["CLK_" + gclk_name + "_GCLKEN"]>
                    <#assign gclken = true>
                <#else>
                    <#assign gclken = false>
                </#if>
                <#if gclken>
                    <#assign gclkcss = .vars["CLK_" + gclk_name + "_GCLKCSS"]>
                    <#assign gclkdiv = .vars["CLK_" + gclk_name + "_GCLKDIV"]>
                <#else>
                    <#assign gclkcss = "0">
                    <#assign gclkdiv = "0">
                </#if>
                <#if clken || gclken>
                    <#if name == "EXT_MEMORY">
                        <#lt>        {ID_SDRAMC, 1U, 0U, 0U, 0U},
                    <#else>
                        <#lt>        {ID_${(name == "PIO")?string("PIOA", name)}, ${clken?then("1U", "0U")}, ${gclken?then("1U", "0U")}, ${gclkcss}U, ${gclkdiv}U},
                    </#if>
                </#if>
            </#if>
        </#list>
        {EOL_MARKER, 0U, 0U, 0U, 0U}//end of list marker
    };

    uint32_t count = sizeof(periphList)/sizeof(periphList[0]);
    for (uint32_t i = 0U; i < count; i++)
    {
        if (periphList[i].id == EOL_MARKER)
        {
            break;
        }

        PMC_REGS->PMC_PCR = PMC_PCR_CMD_Msk |\
                            PMC_PCR_GCLKEN(periphList[i].gclken) |\
                            PMC_PCR_EN(periphList[i].clken) |\
                            PMC_PCR_GCLKDIV(periphList[i].divs) |\
                            PMC_PCR_GCLKCSS(periphList[i].css) |\
                            PMC_PCR_PID(periphList[i].id);
    }

}
<#if CLK_USB_EN>

/*********************************************************************************
Initialize USB OHCI clocks
*********************************************************************************/
static void initUSBClk ( void )
{
    /* Configure USB OHCI clock source and divider */
    PMC_REGS->PMC_USB = PMC_USB_USBDIV(${CLK_USB_USBDIV}U) | PMC_USB_USBS_${CLK_USB_USBS};

    /* Enable UHP48M and UHP12M OHCI clocks */
    PMC_REGS->PMC_SCER |= PMC_SCER_UHP_Msk;
}
</#if>
<#if SYSTEM_COUNTER_ENABLE>

/*********************************************************************************
Initialize system counter
*********************************************************************************/
static void initSystemCounter(void)
{
    /* Turn on GCLK 28 if it is not enabled already  */
    if ((PMC_REGS->PMC_GCSR0 & PMC_GCSR0_GPID28_Msk) == 0U)
    {
        PMC_REGS->PMC_PCR = PMC_PCR_CMD_Msk |\
                            PMC_PCR_GCLKEN(1U) |\
                            PMC_PCR_EN(0U) |\
                            PMC_PCR_GCLKDIV(0U) |\
                            PMC_PCR_GCLKCSS_MAINCK |\
                            PMC_PCR_PID(28U);
        while((PMC_REGS->PMC_GCSR0 & PMC_GCSR0_GPID28_Msk) == 0U)
        {
            /* Wait for GCLK 28 to enabled */
        }
    }

    /* Set timestamp count frequency */
    PSELCTRL_REGS->CNTFID0 = SYSTEM_COUNTER_FREQUENCY;

    /* Enable counter */
    PSELCTRL_REGS->CNTCR |= CNTCR_EN_Msk;

}
</#if>

/*********************************************************************************
Clock Initialize
*********************************************************************************/
void CLK_Initialize( void )
{
    /* Set main crystal frequency for UTMI PLL */
    PMC_REGS->PMC_XTALF = PMC_XTALF_XTALF_${XTALF};
<#if SFRBU_PSWBU_SOFTSWITCH_VBAT>
    SFRBU_REGS->SFRBU_PSWBU = SFRBU_PSWBU_CTRL_SOFT | SFRBU_PSWBU_PSWKEY_PASSWD;
</#if>

<#list PLL_LIST as PLL_NAME>
<#if .vars["CLK_" + PLL_NAME + "_EN"]>
    /* Initialize ${PLL_NAME} */
    initPLL(PLL_ID_${PLL_NAME}, &${PLL_NAME?lower_case}_cfg);

</#if>
</#list>
    <#if CLK_USBPLL_EN>

    /* Initialize USBPLL clock generator */
    initUSBPLLCLK();
    </#if>
    /* Initialize Programmable clock */
    initProgrammableClocks();

    /* Initialize Peripheral clock */
    initPeripheralClocks();
    <#if CLK_USB_EN>

    /* Initialize USB Clock */
    initUSBClk();
    </#if>
<#if SYSTEM_COUNTER_ENABLE>

    /* Initialize system counter (timestamp generator) */
    initSystemCounter();
</#if>
}

