package com.finegamedesign.lava
{
    public class Player2 extends Player
    {
        [Embed(source="../../../../gfx/player2.png")] internal static var Player2Img:Class;

        public function Player2(X:int = 0, Y:int = 0, ImgClass:Class = null) 
        {
            if (null == ImgClass) {
                ImgClass = Player2Img;
            }
            super(X, Y, ImgClass);
        }
    }
}
