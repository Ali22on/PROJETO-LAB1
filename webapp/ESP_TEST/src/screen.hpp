#pragma once
#include <lvgl.h>
#include <Arduino.h>
#define ORANGE 0xF27222
#define YELLOW 0xF5F542
#define GREEN 0x00FF00
#define RED 0xFF0000
#define BLUE 0x0000FF
#define DEFAULT_COLOR 0x2196F7
LV_IMG_DECLARE(ui_img_1651235431);
LV_FONT_DECLARE(ui_font_jetBrainMono18);
LV_FONT_DECLARE(ui_font_jetBrains48);
void init_screen();
extern lv_obj_t *mainScreen;
extern lv_obj_t *pnBase;


class Button
{
private:
public:
    lv_obj_t *btn;
    lv_obj_t *label;
};


void setOnButtonClickCallback(void (*cb)(int));
void setCurrentLabel(uint8_t value);
void setCurrentPlayer(bool player1);