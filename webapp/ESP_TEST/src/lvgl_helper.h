#pragma once
#include <lvgl.h>
#include <TFT_eSPI.h>
#include <Arduino.h>
#include <../lib/boardstuff/boardstuff.h>
#include <NightMareNetwork.h>
#include <./screen.hpp>
#include <UserDefines.h>
#include <Core/Misc.h>
#include <TimeLib.h>

#include <../include/Creds/WifiCred.h>
#ifdef ROTATION
#undef ROTATION
#endif
#define ROTATION ROTATION_LANDSCAPE
/*Change to your screen resolution*/
static const uint16_t screenWidth = 320;
static const uint16_t screenHeight = 240;
static bool sleeping = false;
static lv_disp_draw_buf_t draw_buf;
static lv_color_t buf[screenWidth * screenHeight / 10];
void screen_sleep(uint8_t value);
TFT_eSPI tft = TFT_eSPI(screenWidth, screenHeight); /* TFT instance */
#define GREEN_ACCENT 0x05D742
/* Display flushing */
void my_disp_flush(lv_disp_drv_t *disp, const lv_area_t *area, lv_color_t *color_p)
{
    uint32_t w = (area->x2 - area->x1 + 1);
    uint32_t h = (area->y2 - area->y1 + 1);

    tft.startWrite();
    tft.setAddrWindow(area->x1, area->y1, w, h);
    tft.pushColors((uint16_t *)&color_p->full, w * h, true);
    tft.endWrite();

    lv_disp_flush_ready(disp);
}
//#define DEBUG_TOUCH
/*Read the touchpad*/
void my_touchpad_read(lv_indev_drv_t *indev_driver, lv_indev_data_t *data)
{

    uint16_t touchX = 0, touchY = 0;

    bool touched = tft.getTouch(&touchX, &touchY, 420);
#if ROTATION == ROTATION_PORTRAIT_INV
    touchY = 320 - touchY;
#endif
#if ROTATION == ROTATION_LANDSCAPE
    uint16_t tmp = touchX;
    touchX = touchY;
    touchY = screenHeight - tmp;
#endif
    if (!touched)
    {
        data->state = LV_INDEV_STATE_REL;
    }
    else
    {
       
        if (sleeping)
        {
            screen_sleep(1);
        }
        data->state = LV_INDEV_STATE_PR;

        /*Set the coordinates*/
        data->point.x = touchX;
        data->point.y = touchY;
        // Serial.println("touch detected");
#ifdef DEBUG_TOUCH
        Serial.print("Data x ");
        Serial.println(touchX);

        Serial.print("Data y ");
        Serial.println(touchY);
#endif
    }
}


void lvgl_init()
{
    lv_init();
    tft.begin();               /* TFT init */
    tft.setRotation(ROTATION); /* Landscape orientation, flipped */
    lv_disp_draw_buf_init(&draw_buf, buf, NULL, screenWidth * screenHeight / 10);

    // config_touch_callbacks(); //Configure all callbacks.
    /*Initialize the display*/
    static lv_disp_drv_t disp_drv;
    lv_disp_drv_init(&disp_drv);
    /*Change the following line to your display resolution*/
    disp_drv.hor_res = screenWidth;
    disp_drv.ver_res = screenHeight ;
    disp_drv.flush_cb = my_disp_flush;
    disp_drv.draw_buf = &draw_buf;
    lv_disp_drv_register(&disp_drv);

    /*Initialize the (dummy) input device driver*/

    static lv_indev_drv_t indev_drv;
    lv_indev_drv_init(&indev_drv);
    indev_drv.type = LV_INDEV_TYPE_POINTER;
    indev_drv.read_cb = my_touchpad_read;
    lv_indev_drv_register(&indev_drv);
    uint16_t calData[5] = {405, 3238, 287, 3292, 2};
    tft.setTouch(calData);
    // config_lvgl_touch();
    init_screen();
    set_backlight(0xFF);
    lv_refr_now(NULL);
    set_led(0);
}


#define DIMM_BRIGHTNESS 32
#define DEBUG_SCREEN_SLEEP
#define GET_TOUCH(var) (var == SCREEN_DIMMED_WITH_TOUCH) || (var == SCREEN_ENABLED)
#define SCREEN_SLEEP 0
void screen_sleep(uint8_t value)
{
    if (value == 0)
    {
        tft.writecommand(0x10); // Turn off screen cmd
        set_backlight(0);
        sleeping = true;
    }
    else if (value == 1)
    {
        sleeping = false;
        tft.writecommand(0x11); // Turn on screen cmd
        delay(125);             // Delay for screen to turn on before setting brightness (Prevent screen from all )
        set_backlight(0xFF);
        lv_refr_now(NULL);
    }
}
