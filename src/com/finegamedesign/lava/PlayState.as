package com.finegamedesign.lava
{
    import flash.display.Bitmap;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    import org.flixel.*;
    import org.flixel.plugin.photonstorm.API.FlxKongregate;
   
    public class PlayState extends FlxState
    {
        private static var first:Boolean = true;
        [Embed(source="../../../../gfx/maze20x15.png")]
        private static const Map:Class;
        [Embed(source="../../../../gfx/tiles.png")]
        private static const Tiles:Class;
        private static var textColor:uint = 0xFFFFFF;

        private var state:String;
        private var instructionText:FlxText;
        private var titleText:FlxText;
        private var scoreText:FlxText;
        private var highScoreText:FlxText;
        private var player:Player;
        private var lifeTime:Number;
        private var spawnTime:Number;
        private var enemies:FlxGroup;
        private var cellWidth:int;
        private var map:FlxTilemap;

        private function createScores():void
        {
            if (null == FlxG.scores || FlxG.scores.length <= 0) {
                FlxG.scores = [0];
                FlxG.flashFramerate = 60;
                FlxG.bgColor = 0xFF777777;
                // FlxG.visualDebug = true;
                FlxG.worldBounds = new FlxRect(0, 0, FlxG.width, FlxG.height);
            }
            else {
                FlxG.scores.push(FlxG.score);
            }
            if (9 <= FlxG.score) {
                FlxG.score = 2;
            }
            else {
                FlxG.score = 0;
            }
        }

        override public function create():void
        {
            super.create();
            lifeTime = 0.0;
            spawnTime = 0.0;
            createScores();
            loadMap();
            player = new Player(FlxG.width / 2, FlxG.height / 2);
            player.y -= player.frameHeight / 2;
            player.x -= player.frameWidth / 2;
            add(player);
            enemies = new FlxGroup();
            add(enemies);
            addHud();
            state = "start";
            first = false;
            
            // After stage is setup, connect to Kongregate.
            // http://flixel.org/forums/index.php?topic=293.0
            // http://www.photonstorm.com/tags/kongregate
            if (! FlxKongregate.hasLoaded) {
                FlxKongregate.init(apiHasLoaded);
            }
        }

        private function apiHasLoaded():void
        {
            FlxKongregate.connect();
        }

        private function loadMap():void
        {
            map = new FlxTilemap();
            var image:Bitmap = Bitmap(new Map());
            map.loadMap(FlxTilemap.bitmapToCSV(image.bitmapData), Tiles);
            var pixels:Vector.<uint> = image.bitmapData.getVector(image.bitmapData.rect);
            const LAVA:int = 2;
            const PLAYER:int = 3;
            const PICKUP:int = 4;
            const WIDTH:int = 16
            var tiles:Bitmap = Bitmap(new Tiles());
            var tilePixels:Vector.<uint> = tiles.bitmapData.getVector(tiles.bitmapData.rect);
            for (var p:int = pixels.length - 1; 0 < p; p--) {
                if (tilePixels[LAVA * WIDTH] == pixels[p]) {
                    map.setTileByIndex(p, LAVA);
                }
                else if (tilePixels[PLAYER * WIDTH] == pixels[p]) {
                    map.setTileByIndex(p, PLAYER);
                }
                else if (tilePixels[PICKUP * WIDTH] == pixels[p]) {
                    map.setTileByIndex(p, PICKUP);
                }
            }
            add(map);
        }

        private function addHud():void
        {
            titleText = new FlxText(0, int(FlxG.height * 0.25), FlxG.width, 
                "LAVA TUBES" 
                + "\nGame  by Ethan Kennerly\nPlaytesting by Ian Hill");
            titleText.color = textColor;
            titleText.size = 8;
            titleText.scrollFactor.x = 0.0;
            titleText.scrollFactor.y = 0.0;
            titleText.alignment = "center";
            add(titleText);
            instructionText = new FlxText(0, 0, FlxG.width, 
                first ? "CLICK HERE"
                      : "PRESS ARROW KEYS\nTO RESCUE PRINCESS");
            instructionText.color = textColor;
            instructionText.scrollFactor.x = 0.0;
            instructionText.scrollFactor.y = 0.0;
            instructionText.alignment = "center";
            add(instructionText);
            scoreText = new FlxText(FlxG.width - 30, 0, 30, "0");
            scoreText.color = textColor;
            scoreText.scrollFactor.x = 0.0;
            scoreText.scrollFactor.y = 0.0;
            add(scoreText);
            highScoreText = new FlxText(10, 0, 30, "HI 0");
            setHighScoreText();
            highScoreText.color = textColor;
            highScoreText.scrollFactor.x = 0.0;
            highScoreText.scrollFactor.y = 0.0;
            add(highScoreText);
        }

        override public function update():void 
        {
            if ("lose" != state) {
                updateInput();
            }
            if ("start" == state && (player.velocity.x != 0.0 || player.velocity.y != 0.0))
            {
                state = "pickup";
                instructionText.text = "PRESS ARROW KEYS\nTO RESCUE PRINCESS";
                titleText.text = "";
            }
            if ("play" == state) {
                FlxG.collide(player, map);
                FlxG.overlap(player, enemies, collide);
            }
            updateHud();
            super.update();
        }

        private function updateHud():void
        {
            scoreText.text = FlxG.score.toString();
            setHighScoreText();
        }

        private function setHighScoreText():void
        {
            var highScore:int = int.MIN_VALUE;
            for (var s:int = 0; s < FlxG.scores.length; s++) {
                if (highScore < FlxG.scores[s]) {
                    highScore = FlxG.scores[s];
                }
            }
            if (highScore < FlxG.score) {
                highScore = FlxG.score;
            }
            highScoreText.text = "HI " + highScore;
        }

        private function collide(me:FlxObject, you:FlxObject):void
        {
            var enemy:FlxSprite = FlxSprite(you);
            var player:Player = Player(me);
            var my:FlxPoint = new FlxPoint(player.x + player.frameWidth / 2, player.y + player.frameHeight / 2);
            var yours:FlxPoint = new FlxPoint(enemy.x + enemy.frameWidth / 2, enemy.y + enemy.frameHeight / 2);
            if (0.5 * (enemy.frameWidth + player.frameWidth) < FlxU.getDistance(my, yours)) {
                // FlxG.log("collide " + FlxU.getDistance(my, yours).toFixed(2));
                return;
            }
            player.hurt(1);
            enemy.solid = false;
            if (1 <= player.health) {
                return;
            }
            FlxG.timeScale = 1.0;
            //+ player.play("collide");
            player.velocity.x = 0.0;
            player.velocity.y = 0.0;
            FlxG.play(Sounds.explosion);
            FlxG.camera.shake(0.05, 0.5, null, false, FlxCamera.SHAKE_HORIZONTAL_ONLY);
            instructionText.text = "AA!  LAVA!";
            FlxG.fade(0xFF000000, 4.0, lose);
            FlxG.music.fadeOut(4.0);
            state = "lose";
            FlxKongregate.api.stats.submit("Score", FlxG.score);
        }

        private function lose():void
        {
            FlxG.playMusic(Sounds.music, 0.0);
            FlxG.resetState();
        }

        /**
         * Press arrow key to move.
         * To make it harder, play 2x speed: press Shift+2.  
         * To make it normal again, play 1x speed: press Shift+1.  
         */ 
        private function updateInput():void
        {
            if (FlxG.mouse.justPressed()) {
                titleText.text = "";
                instructionText.text = "PRESS ARROW KEYS\nTO RESCUE PRINCESS";
                FlxG.play(Sounds.start);
            }
            mayMovePlayer();
            mayCheat();
        }

        private function mayMovePlayer():void
        {
            player.velocity.x = 0;
            player.velocity.y = 0;
            if (FlxG.keys.pressed("LEFT") || FlxG.keys.pressed("A")) {
                player.velocity.x -= player.speed;
            }
            if (FlxG.keys.pressed("RIGHT") || FlxG.keys.pressed("D")) {
                player.velocity.x += player.speed;
            }
            if (FlxG.keys.pressed("UP") || FlxG.keys.pressed("W")) {
                player.velocity.y -= player.speed;
            }
            if (FlxG.keys.pressed("DOWN") || FlxG.keys.pressed("S")) {
                player.velocity.y += player.speed;
            }
            player.x = Math.max(player.frameWidth / 2, Math.min(FlxG.width - player.frameWidth, player.x));
            player.y = Math.max(player.frameHeight / 2, Math.min(FlxG.height - player.frameHeight, player.y));
        }

        private function mayCheat():void
        {
            if (FlxG.keys.pressed("SHIFT")) {
                if (FlxG.keys.justPressed("ONE")) {
                    if (FlxG.timeScale != 1.0) {
                        FlxG.music.pause();
                        FlxG.music.resume(1000.0 * lifeTime);
                        // FlxG.log("resume " + FlxG.music.channel.position);
                        FlxG.timeScale = 1.0;
                    }
                }
                else if (FlxG.keys.justPressed("TWO")) {
                    FlxG.timeScale *= 2.0;
                }
                else if (FlxG.keys.justPressed("THREE")) {
                    FlxG.timeScale *= 0.5;
                }
                else if (FlxG.keys.justPressed("NINE")) {
                    player.health = player.health < 2 ? int.MAX_VALUE : 1;
                    player.alpha = 0.5 + (player.health < 2 ? 0.5 : 0.0);
                }
            }
        }
    }
}
