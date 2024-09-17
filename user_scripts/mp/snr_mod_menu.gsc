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
#include user_scripts\mp\utils\snr_menu_utils;

// Initialize the mod menu by precaching shaders, configuring settings, 
// and setting up event listeners for player connections and game end.
init() {
    // Pre-cache shaders for later use in the menu.
    preCacheShader("gradient_fadein");
    preCacheShader("gradient");
    preCacheShader("white");
    preCacheShader("line_vertical");

    // Configure the mod menu settings.
    ModMenuConfig();

    // Start listening for players connecting and the game ending.
    level thread onPlayerConnected();
    level thread onGameEnded();
}

// Wait for the game to end and close any open mod menus for all players.
onGameEnded() {
    // Wait until the game has ended.
    level waittill("game_ended");

    // Iterate through all players in the game.
    foreach(p in level.players) {
        // If the player has the mod menu open, close it.
        if (isDefined(p.uimodmenuOpen) && p.uimodmenuOpen) {
            p thread destroyModMenu();
        }
    }
}

// Continuously listen for new players connecting, and set up their mod menu controls.
onPlayerConnected() {
    // End this thread when the game ends.
    level endon("game_ended");
    
    // Infinite loop to keep checking for new players.
    for (;;) {
        // Wait until a player connects.
        level waittill("connected", player);
        
        // Skip bots, only set up menus for real players.
        if (isSubStr(player.guid, "bot"))
            continue;
        
        // Create the player's mod menu and set up input listeners.
        player CreatePlayerMenu();
        player thread onPlayerDeath();
        player thread openModMenuListener();
        player thread commandListener();
    }
}

// Configure the mod menu with default settings and initialize the menu structure.
ModMenuConfig() {
    // Set the menu scroll color, background color, and title, if not already set.
	setDvarIfNotInit("snr_menu_scrollcolor", "yellow");
	setDvarIfNotInit("snr_menu_backgroundcolor", "grey");
    setDvarIfNotInit("snr_menu_title", "S&R Menu");

    // Set the delay time between button presses.
    level.buttonDelayTime = 230;

    // Initialize the mod menu structure as an empty array.
    self.structmodmenu = [];
}

// Set a DVAR (game variable) only if it hasn't been initialized already.
setDvarIfNotInit(dvarName, value) {
    if (getDvar(dvarName) == "") {
        setDvar(dvarName, value);
    }
}

// Create the mod menu structure for the player with buttons and actions.
CreatePlayerMenu() {
    // Add buttons to the main page with titles and corresponding actions.
    addButton("main", "Page 1", ::goToPage1);
    addButton("main", "Credits", ::goToCreditsMenu);
    addText("main", "^3[{+attack}] ^7 - ^3[{+speed_throw}] ^7 - ^3[{+gostand}]");

    addText("credits", "S&R Mods menu was developed");
    addText("credits", "by Shockeh at S&R Servers.");
    addText("credits", "More about us: SnRServers.com/about");
    addButton("credits", "^1Back", ::goToMain);

    // Add buttons to the first page with test functions and a back option.
    addButton("page1", "Test function", user_scripts\mp\snr_menu_functions\snr_menu_functions::testMenuFunction);
    addButton("page1", "Test function", user_scripts\mp\snr_menu_functions\snr_menu_functions::testMenuFunction);
    addText("page1", "Test text");
    addButton("page1", "^1Back", ::goToMain);
}

goToCreditsMenu() {
    switchPage("credits");
}

goToMain() {switchPage("main");}
goToPage1() { switchPage("page1");}
goToPage2() { switchPage("page2");}
goToPage3() { switchPage("page3");}
buttonDynamicText() {  
    return "Page 3 (Dynamic Text)";
}

noaction() {}

vipButtonText() {
    if (!isDefined(self.pers["roleApplied"]) || !self.pers["roleApplied"]) {
        if (isDefined(self.pers["roleError"]) && self.pers["roleError"]) {
            return "Status: ^1Network Error";
        } else {
            return "Status: Connecting...";
        }
    } else {
        if (!isDefined(self.pers["roleId"]) || self.pers["roleId"] == 0)
            return "^3Upgrade to VIP";
        else 
            return "Status: " + user_scripts\mp\snr_roles::roleIdToName(self.pers["roleId"]);
    }
}

switchPage(page) {
    self.currentPage = page;
    if ((isDefined(self.uimodmenuOpen) && self.uimodmenuOpen)) {
        self destroyModMenu();
    }
    self DisplayModMenu();
    self.switchPageTime = gettime();
}

resetPage() {
    self.currentPage = "main";
}

openModMenuListener() {
    level endon("game_ended");

    for (;;) {
        self waittill("snr_menu_open");
        
        if (isAlive(self) && (!isDefined(self.uimodmenuOpen) || !self.uimodmenuOpen)){
            self switchPage("main");
        }
    }
}

addButton(page, title, actionFun, buttonDynamicText) {
    // Check if the menu structure for the given page is defined; if not, initialize it as an empty array.
    if (!isDefined(self.structmodmenu[page])) {
        self.structmodmenu[page] = [];
    }

    // Check if the button text array for the page is defined; if not, initialize it along with actions and dynamic text arrays.
    if (!isDefined(self.structmodmenu[page]["buttonText"])) {
        self.structmodmenu[page]["buttonText"] = [];
        self.structmodmenu[page]["actions"] = [];
        self.structmodmenu[page]["buttonDynamicText"] = [];
        self.structmodmenu[page]["scrollable"] = [];
    }
    
    // Get the index for the new button based on the current size of the buttonText array.
    index = self.structmodmenu[page]["buttonText"].size;
    
    // Add the new button's title, action function, and dynamic text to their respective arrays at the determined index.
    self.structmodmenu[page]["buttonText"][index] = title;
    self.structmodmenu[page]["actions"][index] = actionFun;
    self.structmodmenu[page]["buttonDynamicText"][index] = buttonDynamicText;
    self.structmodmenu[page]["scrollable"][index] = true;
}


addText(page, title) {
    // Check if the menu structure for the given page is defined; if not, initialize it as an empty array.
    if (!isDefined(self.structmodmenu[page])) {
        self.structmodmenu[page] = [];
    }

    // Check if the button text array for the page is defined; if not, initialize it along with actions and dynamic text arrays.
    if (!isDefined(self.structmodmenu[page]["buttonText"])) {
        self.structmodmenu[page]["buttonText"] = [];
        self.structmodmenu[page]["actions"] = [];
        self.structmodmenu[page]["buttonDynamicText"] = [];
    }
    
    // Get the index for the new button based on the current size of the buttonText array.
    index = self.structmodmenu[page]["buttonText"].size;
    
    // Add the new button's title, action function, and dynamic text to their respective arrays at the determined index.
    self.structmodmenu[page]["buttonText"][index] = title;
    self.structmodmenu[page]["actions"][index] = undefined;
    self.structmodmenu[page]["buttonDynamicText"][index] = undefined;
    self.structmodmenu[page]["scrollable"][index] = false;
}

DisplayModMenu()
{
    self endon("disconnect");
    level endon("game_ended");

    /*if (!self isOnGround())
        return;*/ // Need to comment this or othrwise unstuck won't work.

    self.uimodmenuOpen = true;
    self.openMenuTime = gettime();

    // Set scroll and background colors based on dvar values
    scrollcolor = getColor(getDvar("snr_menu_scrollcolor"));
    bgcolor = getColor(getDvar("snr_menu_backgroundcolor"));

    // Apply blur effect and freeze controls
    self freezeControlsWrapper(1);
    self freezeControls(true);
    boxes = [];

    // Menu sizes, you can configure them here;
    width = 250;
    size = 26;
    padding = 4;
    startMargin = size * 2;
    // Calculate the height of the container based on the number of buttons
    containerHeight = size * self.structmodmenu[self.currentPage]["buttonText"].size + startMargin;

    self.uimodmenu = spawnStruct();
    // Create background boxes
    self.uimodmenu.backgroundBox = self CreateRectangle("center", "center", 0, 0, width + 2, containerHeight, bgcolor, "white", 1, 1);
    self.uimodmenu.backgroundBox1 = self CreateRectangle("center", "center", 0, 0, width + 2 + padding, containerHeight + padding, scrollcolor, "white", 0, 0.3);

    // Create the title element, positioned just above the menu
    self.uimodmenu.title = self createFontString("objective", 1.9);
    self.uimodmenu.title setPoint("center", "center", 0, -containerHeight / 2 + startMargin /2); // Position just above the top of the menu
    self.uimodmenu.title setText(getDvar("snr_menu_title"));
    self.uimodmenu.title.hidewheninmenu = true;

    self.uimodmenu.boxes = [];
    self.uimodmenu.textlinebackground = [];
    self.uimodmenu.textline = [];

    seperatorHeight = 1;
    self.uimodmenu.seperators = [];
    self.uimodmenu.seperators[0] = self CreateRectangle("center", "center", 0, -containerHeight/2 + startMargin - seperatorHeight, width + 2, seperatorHeight, scrollColor, "white", 3, 1);
    self.uimodmenu.seperators[0] changeProperty("alpha", 0, 0.6);

    // Loop through and create each button
    for (i = 0; i < self.structmodmenu[self.currentPage]["buttonText"].size; i++) {
        color = bgColor;

        // Create box background for each button
        self.uimodmenu.boxes[i] = self CreateRectangle("center", "center", 0, -containerHeight/2 + startMargin + size/2 + size * i, width + 2, size, color, "white", 2, 1);

        // Create the text line background for each button
        self.uimodmenu.textlinebackground[i] = self CreateRectangle("center", "center",  0, -containerHeight/2 + startMargin + size/2 + size * i, width, size - 2, (0.12, 0.12, 0.12), "white", 3, 0, 0);
        self.uimodmenu.textlinebackground[i] changeProperty("alpha", 0, 0.6);

        // Add the button text
        text = "";
        dynamicTextFun = self.structmodmenu[self.currentPage]["buttonDynamicText"][i];

        dynamicText = [[dynamicTextFun]]();

        if (isDefined(dynamicText))
            text = dynamicText;
        else 
            text = self.structmodmenu[self.currentPage]["buttonText"][i];

        self.uimodmenu.textline[i] = self CreateString(text, "objective", 1, "center", "center", 0, -containerHeight/2 + startMargin + size/2 + i * size, (1, 1, 1), 1, (0, 0, 0), 0.5, 5, 0);
    }

    self thread handleMenuNavigation();
}
// Helper function to select and highlight a button
selectButton(index, scrollcolor, bgcolor)
{
    // Set scroll and background colors based on dvar values
    scrollcolor = getColor(getDvar("snr_menu_scrollcolor"));
    bgcolor = getColor(getDvar("snr_menu_backgroundcolor"));

    // Deselect the current box
    self.uimodmenu.boxes[self.selectedBox] changeProperty("color", 0.1, bgcolor);
    
    // Select the new box
    self.uimodmenu.boxes[index] changeProperty("color", 0.1, scrollcolor);
    
    // Update the selected box
    self.selectedBox = index;
}

// Listen for input events and handle the menu navigation
handleMenuNavigation()
{
    level endon("game_ended");
    self endon("destroyModMenu");
    selectedIndex = self findNextScrollableBox(-1);

    // Initialize the selection
    self selectButton(selectedIndex);

    while (true)
    {
        command = self waittill_any_return("snr_menu_left", "snr_menu_right", "snr_menu_select", "snr_menu_close", "disconnect", "death");
        switch (command) {
            
            case "snr_menu_left":
                // Find the previous scrollable box using recursion
                selectedIndex = self findPreviousScrollableBox(selectedIndex);

                // Select the new box
                self selectButton(selectedIndex);
                wait 0.1;
                break;

            case "snr_menu_right":
                // Find the next scrollable box using recursion
                selectedIndex = self findNextScrollableBox(selectedIndex);

                // Select the new box
                self selectButton(selectedIndex);
                wait 0.1;
                break;

            case "snr_menu_select":
                // Prevent double-clicking within a short time period
                if (isDefined(self.lastSelectTime) && self.lastSelectTime > 0 && gettime() - self.lastSelectTime < 400)
                    continue;
                
                self.lastSelectTime = gettime();
                self.selectedBox = selectedIndex;
                self thread handleSelectUi(self.currentPage, selectedIndex);
                
                // Call the action associated with the selected button
                self thread [[self.structmodmenu[self.currentPage]["actions"][selectedIndex]]]();
                wait 0.1;
                break;

            case "snr_menu_close":
                // Prevent closing the menu too quickly after opening
                if (isDefined(self.openMenuTime) && gettime() - self.openMenuTime < level.buttonDelayTime) {
                    continue;
                }
                // Fall through to execute the same code as "disconnect" and "death"

            case "disconnect":
            case "death":
                self.selectedBox = 0;            
                self resetPage();
                self destroyModMenu();
                break;

            default:
                // Optional: handle unknown commands or do nothing
                break;
        }
    }
}



// Helper function to find the previous scrollable box using recursion
findPreviousScrollableBox(index)
{
    index--;

    if (index < 0)
        index = self.uimodmenu.boxes.size - 1;

    if (!self.structmodmenu[self.currentPage]["scrollable"][index]) {
        // Recursive call if the current box is not scrollable
        return self findPreviousScrollableBox(index);
    }

    return index;
}

// Helper function to find the next scrollable box using recursion
findNextScrollableBox(index)
{
    index++;

    if (index >= self.uimodmenu.boxes.size)
        index = 0;

    if (!self.structmodmenu[self.currentPage]["scrollable"][index]) {
        // Recursive call if the current box is not scrollable
        return self findNextScrollableBox(index);
    }

    return index;
}

handleSelectUi(page, selectedIndex) {
    self endon("destroyModMenu");
    // Set scroll and background colors based on dvar values
    scrollcolor = getColor(getDvar("snr_menu_scrollcolor"));
    bgcolor = getColor(getDvar("snr_menu_backgroundcolor"));

    selectcolor = getColor(getDvar("snr_menu_selectcolor"));
    self.uimodmenu.boxes[selectedIndex] changeProperty("color", 0.1, selectcolor);
    wait .1;
    color = undefined;

    if (self.selectedBox == selectedIndex) {
        color = scrollcolor;
    } else {
        color = bgcolor;
    }
    
    self.uimodmenu.boxes[selectedIndex] changeProperty("color", 0.1, color);
}

// Listens for user inputs;
commandListener() {
	level endon("game_ended");

	while (true) {
		wait .05;
        
        // If the player is not alive, skip the rest of the loop and continue to the next iteration.
        if (!isAlive(self))
            continue;

        // If the pre-match period is not done, skip the rest of the loop and continue to the next iteration.
        if (!maps\mp\_utility::gameflag("prematch_done")) {
            continue;
        }

        if (self meleeButtonPressed()) {
            if (self adsButtonPressed() && (!isDefined(self.uimodmenuOpen) || !self.uimodmenuOpen)) {
                self notify("snr_menu_open");
            } else if (isDefined(self.uimodmenuOpen) && self.uimodmenuOpen) {
                self notify("snr_menu_close");
            }
            // Wait for a short duration before proceeding to avoid multiple inputs.
            wait 0.05;
        } 
        else if (self adsButtonPressed()) {
            // If the delay time for switching pages has not passed, skip the rest of the loop.
            if (isDefined(self.switchPageTime) && gettime() - self.switchPageTime < level.buttonDelayTime)
                continue;

			self notify("snr_menu_left");
            // Wait for a short duration before proceeding to avoid multiple inputs.
			wait 0.05;
		} 
        else if (self attackButtonPressed()) {
			self notify("snr_menu_right");
            // Wait for a short duration before proceeding to avoid multiple inputs.
			wait 0.05;
 		} 
        else if (self UseButtonPressed() || self jumpButtonPressed()) {
            // If the delay time for switching pages has not passed, skip the rest of the loop.
            if (isDefined(self.switchPageTime) && gettime() - self.switchPageTime < level.buttonDelayTime)
                continue;

			self notify("snr_menu_select");
            // Wait for a short duration before proceeding to avoid multiple inputs.
			wait 0.05;
		}
	}
}

destroyModMenu()
{
    if (!(isDefined(self.uimodmenuOpen) && self.uimodmenuOpen)) {
        return;
    }

    self.uimodmenuOpen = false;

    // Destroy all created elements
    foreach (box in self.uimodmenu.boxes) {
        box destroy();
    }

    self.uimodmenu.title destroy();
    self.uimodmenu.backgroundBox destroy();
    self.uimodmenu.backgroundBox1 destroy();

    foreach (line in self.uimodmenu.textline) {
        line destroy();
    }
    
    foreach (lineBackground in self.uimodmenu.textlinebackground) {
        lineBackground destroy();
    }
    
    foreach (seperator in self.uimodmenu.seperators) {
        seperator destroy();
    }

    // Restore the player's controls and remove blur
    if (!level.gameEnded) {
        self freezeControlsWrapper(0);
    }

    self notify("destroyModMenu");
}

// Listen for the player's death and destroy their mod menu when they die.
onPlayerDeath() {
    level endon("game_ended");

    for (;;) {
        self waittill("death");
        // Destroy the player's mod menu upon death.
        self destroyModMenu();
    }
}
