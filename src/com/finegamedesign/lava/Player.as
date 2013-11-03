package com.finegamedesign.lava
{
    import org.flixel.*;

    public class Player extends FlxSprite
    {
        [Embed(source="../../../../gfx/player.png")] internal static var PlayerImg:Class;
        internal var speed:Number = 60;
                                    // 160;

        public function Player(X:int = 0, Y:int = 0, ImgClass:Class = null) 
        {
            if (null == ImgClass) {
                ImgClass = PlayerImg;
            }
            super(X, Y, ImgClass);
            width = 0.75 * frameWidth;
            height = 0.75 * frameHeight;
            offset.x = 0.5 * (frameWidth - width);
            offset.y = 0.5 * (frameHeight - height);
            // loadGraphic(Img, true, false, 16, 16, true);
            //+ addAnimation("left", [0], 30, true);
            //+ addAnimation("right", [1], 30, true);
            //+ addAnimation("collide", [2], 30, true);
            //+ addAnimation("idle", [3, 4, 5, 6], 30, true);
            //+ play("idle");
        }
    }
}
