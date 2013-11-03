package com.finegamedesign.lava
{
    import org.flixel.*;
    [SWF(width="640", height="480", backgroundColor="#777777")]
    [Frame(factoryClass="Preloader")]

    public class Main extends FlxGame
    {
        public function Main()
        {
            super(640, 480, PlayState, 1);
        }
    }
}
