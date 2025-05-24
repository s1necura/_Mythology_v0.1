void onInit(CRules@ this)
{
  print("===============");
  print("Mod is running!");
  print("Mod is running!");
  print("Mod is running!");
  print("===============");
  print("Mod is running!");
  print("Mod is running!");
  print("Mod is running!");
  print("===============");
  print("Mod is running!");
  print("Mod is running!");
  print("Mod is running!");
  print("===============");

  getDriver().SetShader("hq2x", false); // disable vanilla shader
    getDriver().ForceStartShaders(); // force enable shaders (most players have shaders disabled)
    getDriver().AddShader("Fog", 3); // add your shader, 3 is the layer, you need to use higher than 2
    getDriver().SetShader("Fog", true); // enable your shader
}


void onTick(CRules@ this)
{
  Driver@ driver = getDriver();

    if (!driver.ShaderState()) 
    {
        driver.ForceStartShaders(); // force enable shaders at all times
    }
    
    if(this.get_bool("testShader"))
    {
        getDriver().SetShaderFloat("testShader", "time",getGameTime());
    }
	
	Vec2f center = getLocalPlayerBlob() is null ? Vec2f(getScreenWidth() / 2.0, getScreenHeight() / 2.0) : getLocalPlayerBlob().getScreenPos(); 

    center /= Vec2f(getScreenWidth(), getScreenHeight());
        center.y = 1.0 - center.y; 
	getDriver().SetShaderFloat("Fog", "centerposx", center.x);
	getDriver().SetShaderFloat("Fog", "centerposy", center.y);
    getDriver().SetShaderFloat("Fog", "zoomlevel", 1.0 / getCamera().targetDistance);
    getDriver().SetShaderFloat("Fog", "gametime", getGameTime() / 1.0);
    getDriver().SetShaderFloat("Fog", "density", 0.5f);

    getDriver().SetShaderFloat("Fog", "screenWidth", getScreenWidth());
    getDriver().SetShaderFloat("Fog", "screenHeight", getScreenHeight());
    
	
}
