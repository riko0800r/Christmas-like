return {
  
  -- basic settings:
  name = 'Christmas-like', -- name of the game for your executable
  developer = 'Riko', -- dev name used in metadata of the file
  output = 'dist', -- output location for your game, defaults to $SAVE_DIRECTORY
  version = '1.0', -- 'version' of your game, used to name the folder in output
  love = '11.5', -- version of LÖVE to use, must match github releases
  icon = 'assets/ICONGAME.png', -- 256x256px PNG icon for game, will be converted for you
  
  -- optional settings:
  use32bit = false, -- set true to build windows 32-bit as well as 64-bit
  identifier = 'com.riko.christmaslike', -- macos team identifier, defaults to game.developer.name
  platforms = {'windows', 'macos', 'linux'},
}