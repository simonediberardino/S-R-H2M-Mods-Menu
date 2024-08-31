/*
    S&R Mod Menu created by Shockeh from S&R Servers

    This script implements a customizable in-game mod menu for players, 
    providing various functions and configurations. The menu allows 
    players to navigate through different pages, execute actions, and 
    interact with the game.

    Developed by Shockeh, owner and developer of the S&R Servers. If 
    you enjoy this mod or want to explore more of our work, feel free 
    to visit our online platforms:

    About S&R Servers
    Twitter: https://x.com/SnRServers
    Website: https://snrservers.com

    About Shockeh
    Twitter: https://x.com/Shockehz
    Github: https://github.com/simonediberardino

    Thank you for using our mod! If you have any feedback or suggestions,
    please reach out through our social media channels.
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\gametypes\_gamelogic;

ValidateColor(value)
{
	return value == "0" || value == "1" || value == "2" || value == "3" || value == "4" || value == "5" || value == "6" || value == "7";
}


GetColor(color)
{
	switch (tolower(color))
	{
		case "red": return (0.960, 0.180, 0.180);
		case "black": return (0, 0, 0);
		case "grey": return (0.1, 0.1, 0.1);
		case "purple": return (1, 0.282, 1);
		case "pink": return (1, 0.623, 0.811);
		case "green": return (0, 0.69, 0.15);
		case "blue": return (0, 0, 1);
		case "lightblue":
		case "light blue": return (0.152, 0329, 0.929);
		case "lightgreen":
		case "light green": return (0.09, 1, 0.09);
		case "orange": return (0.8, 0.4, 0);
		case "yellow": return (0.678, 0.635, 0.274);
		case "brown": return (0.501, 0.250, 0);
		case "cyan": return (0, 1, 1);
		case "white": return (1, 1, 1);
	}
}

CreateString(input, font, fontScale, align, relative, x, y, color, alpha, glowColor, glowAlpha, sort, isLevel)
{
	if (self != level)
		hud = self createFontString(font, fontScale);
	else
		hud = level createServerFontString(font, fontScale);

	hud setText(input);

	hud.x = x;
	hud.y = y;
	hud.align = align;
	hud.horzalign = align;
	hud.vertalign = relative;

	hud setPoint(align, relative, x, y);

	hud.color = color;
	hud.alpha = alpha;
	hud.glowColor = glowColor;
	hud.glowAlpha = glowAlpha;
	hud.sort = sort;
	hud.alpha = alpha;
	hud.archived = 0;
	hud.hideWhenInMenu = 1;
	return hud;
}

CreateRectangle(align, relative, x, y, width, height, color, shader, sort, alpha, islevel)
{
	if (self == level)
		boxElem = newhudelem();
	else
		boxElem = newclienthudelem(self);
	boxElem.elemType = "bar";
	boxElem.width = width;
	boxElem.height = height;
	boxElem.align = align;
	boxElem.relative = relative;
	boxElem.horzalign = align;
	boxElem.vertalign = relative;
	boxElem.xOffset = 0;
	boxElem.yOffset = 0;
	boxElem.children = [];
	boxElem.sort = sort;
	boxElem.color = color;
	boxElem.alpha = alpha;
	boxElem setParent(level.uiParent);
	boxElem setShader(shader, width, height);
	boxElem.hidden = 0;
	boxElem setPoint(align, relative, x, y);
	boxElem.hideWhenInMenu = 0;
	boxElem.archived = 0;
	return boxElem;
}

changeProperty(type, time, value)
{
	if (type == "x" || type == "y")
		self moveOverTime(time);
	else
		self fadeOverTime(time);
	if (type == "x")
		self.x = value;
	if (type == "y")
		self.y = value;
	if (type == "alpha")
		self.alpha = value;
	if (type == "color")
		self.color = value;
}