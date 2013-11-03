package com.finegamedesign.lava
{
    import flash.display.Bitmap;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    import org.flixel.*;
    import org.flixel.plugin.photonstorm.API.FlxKongregate;
   
    public class PlayState extends FlxState
    {
        private static const FLOOR:int = 0;
        private static const WALL:int = 1;
        private static const LAVA:int = 2;
        private static const PLAYER:int = 3;
        private static const PLAYER2:int = 4;
        private static const WIDTH:int = 16
        private static var first:Boolean = true;
        [Embed(source="../../../../gfx/maze20x15.png")]
        private static const Map:Class;
        [Embed(source="../../../../gfx/tiles.png")]
        private static const Tiles:Class;
        [Embed(source="../../../../gfx/palette.png")]
        private static const Palette:Class;
        private static var textColor:uint = 0xFFFFFF;

        private var state:String;
        private var instructionText:FlxText;
        private var titleText:FlxText;
        private var scoreText:FlxText;
        private var highScoreText:FlxText;
        private var player:Player;
        private var player2:Player2;
        private var lifeTime:Number;
        private var enemies:FlxGroup;
        private var map:FlxTilemap;
        private var expandLavaElapsed:Number;
        private var expandLavaTime:Number = 1.0;

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
            expandLavaElapsed = 0.0;
            createScores();
            loadMap();
            add(player2);
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
            var palette:Bitmap = Bitmap(new Palette());
            var palettePixels:Vector.<uint> = palette.bitmapData.getVector(palette.bitmapData.rect);
            for (var p:int = pixels.length - 1; 0 <= p; p--) {
                if (palettePixels[LAVA] == pixels[p]) {
                    map.setTileByIndex(p, LAVA);
                }
                else if (palettePixels[PLAYER] == pixels[p]) {
                    // map.setTileByIndex(p, PLAYER);
                    player = new Player();
                    placePlayer(player, p);
                }
                else if (palettePixels[PLAYER2] == pixels[p]) {
                    // map.setTileByIndex(p, PLAYER2);
                    player2 = new Player2();
                    placePlayer(player2, p);
                }
            }
            add(map);
        }

        private function placePlayer(player:Player, p:int):void
        {
            player.y = WIDTH * int(p / map.widthInTiles)
                + player.frameHeight / 2;
            player.x = WIDTH * (p % map.widthInTiles)
                + player.frameWidth / 2;
        }

        private function expandLava():void
        {
            var neighbors:Array = [];
            var neighbor:int;
            var widthInTiles:int = map.widthInTiles;
            var totalTiles:int = map.totalTiles;
            for (var i:int = 0; i < totalTiles; i++) {
                if (LAVA == map.getTileByIndex(i)) {
                    neighbor = i - widthInTiles;
                    if (0 <= neighbor && FLOOR == map.getTileByIndex(neighbor) && neighbors.indexOf(neighbor) <= -1) {
                        neighbors.push(neighbor);
                    }
                    neighbor = i - 1;
                    if (0 <= neighbor && (neighbor % widthInTiles) <= (widthInTiles - 2) && FLOOR == map.getTileByIndex(neighbor) && neighbors.indexOf(neighbor) <= -1) {
                        neighbors.push(neighbor);
                    }
                    neighbor = i + 1;
                    if (neighbor < totalTiles && 1 <= (neighbor % widthInTiles) && FLOOR == map.getTileByIndex(neighbor) && neighbors.indexOf(neighbor) <= -1) {
                        neighbors.push(neighbor);
                    }
                    neighbor = i + widthInTiles;
                    if (neighbor < totalTiles && FLOOR == map.getTileByIndex(neighbor) && neighbors.indexOf(neighbor) <= -1) {
                        neighbors.push(neighbor);
                    }
                }
            }
            for (i = neighbors.length - 1; 0 <= i; i--) {
                map.setTileByIndex(neighbors[i], LAVA);
            }
        }

        private function addHud():void
        {
            titleText = new FlxText(0, int(FlxG.height * 0.25), FlxG.width, 
                "LAVA MAZE" 
                + "\nGame  by Ethan Kennerly\nPlaytesting by Ian Hill");
            titleText.color = textColor;
            titleText.size = 8;
            titleText.scrollFactor.x = 0.0;
            titleText.scrollFactor.y = 0.0;
            titleText.alignment = "center";
            add(titleText);
            instructionText = new FlxText(0, 0, FlxG.width, 
                first ? "CLICK HERE"
                      : "PRESS ARROW KEYS\nTO REACH PARTNER");
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
            if ("lose" != state && "win" != state) {
                updateInput();
            }
            if ("start" == state 
                    && ((player.velocity.x != 0.0 || player.velocity.y != 0.0)
                    || (player2.velocity.x != 0.0 || player2.velocity.y != 0.0)))
            {
                state = "play";
                instructionText.text = "PRESS ARROW KEYS\nTO REACH PARTNER";
                titleText.text = "";
            }
            expandLavaElapsed += FlxG.elapsed;
            if (expandLavaTime <= expandLavaElapsed) {
                expandLava();
                expandLavaElapsed -= expandLavaTime;
            }
            if ("play" == state) {
                FlxG.collide(player, map);
                FlxG.collide(player2, map);
                FlxG.overlap(player, player2, collidePlayer);
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

        private function collidePlayer(me:FlxObject, you:FlxObject):void
        {
            instructionText.text = "LET'S GET OUT OF HERE!";
            FlxG.fade(0xFFFFFFFF, 4.0, win);
            // FlxG.music.fadeOut(4.0);
            state = "win";
            FlxKongregate.api.stats.submit("Score", FlxG.score);
        }

        private function collideLava(me:FlxObject, you:FlxObject):void
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
            // FlxG.music.fadeOut(4.0);
            state = "lose";
            FlxKongregate.api.stats.submit("Score", FlxG.score);
        }

        private function lose():void
        {
            // FlxG.playMusic(Sounds.music, 0.0);
            FlxG.resetState();
        }

        private function win():void
        {
            // FlxG.playMusic(Sounds.music, 0.0);
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
                instructionText.text = "PRESS ARROW KEYS\nTO REACH PARTNER";
                FlxG.play(Sounds.start);
            }
            mayMovePlayer();
            mayMovePlayer2();
            mayCheat();
        }

        private function mayMovePlayer():void
        {
            player.velocity.x = 0;
            player.velocity.y = 0;
            if (FlxG.keys.pressed("A")) {
                player.velocity.x -= player.speed;
            }
            if (FlxG.keys.pressed("D")) {
                player.velocity.x += player.speed;
            }
            if (FlxG.keys.pressed("W")) {
                player.velocity.y -= player.speed;
            }
            if (FlxG.keys.pressed("S")) {
                player.velocity.y += player.speed;
            }
            player.x = Math.max(player.frameWidth / 2, Math.min(FlxG.width - player.frameWidth, player.x));
            player.y = Math.max(player.frameHeight / 2, Math.min(FlxG.height - player.frameHeight, player.y));
        }

        private function mayMovePlayer2():void
        {
            player2.velocity.x = 0;
            player2.velocity.y = 0;
            if (FlxG.keys.pressed("LEFT")) {
                player2.velocity.x -= player2.speed;
            }
            if (FlxG.keys.pressed("RIGHT")) {
                player2.velocity.x += player2.speed;
            }
            if (FlxG.keys.pressed("UP")) {
                player2.velocity.y -= player2.speed;
            }
            if (FlxG.keys.pressed("DOWN")) {
                player2.velocity.y += player2.speed;
            }
            player2.x = Math.max(player2.frameWidth / 2, Math.min(FlxG.width - player2.frameWidth, player2.x));
            player2.y = Math.max(player2.frameHeight / 2, Math.min(FlxG.height - player2.frameHeight, player2.y));
        }

        private function mayCheat():void
        {
            if (FlxG.keys.pressed("SHIFT")) {
                if (FlxG.keys.justPressed("ONE")) {
                    if (FlxG.timeScale != 1.0) {
                        // FlxG.music.pause();
                        // FlxG.music.resume(1000.0 * lifeTime);
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
