package com.finegamedesign.lava
{
    import flash.display.Bitmap;

    import org.flixel.*;
    import org.flixel.plugin.photonstorm.API.FlxKongregate;
    import org.flixel.system.FlxTile;
   
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
        private static const Maze20x15:Class;
        [Embed(source="../../../../gfx/maze_move.png")]
        private static const MazeMove:Class;
        [Embed(source="../../../../gfx/maze_path.png")]
        private static const MazePath:Class;
        [Embed(source="../../../../gfx/maze_lava.png")]
        private static const MazeLava:Class;
        private static var maps:Array = [MazeMove, 
                                         MazePath,
                                         MazeLava,
                                         Maze20x15];
        [Embed(source="../../../../gfx/tiles.png")]
        private static const Tiles:Class;
        [Embed(source="../../../../gfx/palette.png")]
        private static const Palette:Class;
        private static var textColor:uint = 0xFFFFFF;
        private static var messages:Array = [
            "PRESS ARROW KEYS OR WASD\nTO REACH  YOUR PARTNER",
            "PRESS ARROW KEYS OR WASD\nTO MOVE AROUND WALLS",
            "REACH  YOUR PARTNER!\nAVOID RED LAVA!",
            "QUICK! REACH YOUR PARTNER!\nAVOID RED LAVA!",
            "FOR HIGH SCORE, ARRIVE QUICKLY." ];

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
            if (FlxG.level <= 0) {
                FlxG.score = 0;
            }
        }

        override public function create():void
        {
            super.create();
            lifeTime = 0.0;
            expandLavaElapsed = 0.0;
            createScores();
            FlxG.levels = maps;
            if (isNaN(FlxG.level) || FlxG.level <= 0) {
                FlxG.level = 0;
            }
            loadMap(FlxG.levels[FlxG.level]);
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

        private function loadMap(MapClass:Class):void
        {
            map = new FlxTilemap();
            var image:Bitmap = Bitmap(new MapClass());
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
            var titleMessage:String;
            if (0 == FlxG.level) {
                titleMessage = "LAVA  MAZE" 
                    + "\nFor  one or two players"
                    + "\n\nOne-day game by Ethan Kennerly"
                    + "\nPlaytesting by Ian Hill"
                    + "\n\nFor The Arbitrary Game Jam #4  on November 2, 2013."
                    + "\nTAG4 themes:  Lava & Love Hurts & Be a stranger to fear";
            }
            else {
                titleMessage = "";

            }
            titleText = new FlxText(0, int(FlxG.height * 0.25), FlxG.width, titleMessage); 
            titleText.color = textColor;
            titleText.size = 8;
            titleText.scrollFactor.x = 0.0;
            titleText.scrollFactor.y = 0.0;
            titleText.alignment = "center";
            add(titleText);
            var instructionMessage:String;
            if (first) {
                instructionMessage = "CLICK HERE";
            }
            else {
                instructionMessage = nextInstruction();
            }
            instructionText = new FlxText(0, 0, FlxG.width, instructionMessage);
            instructionText.color = textColor;
            instructionText.scrollFactor.x = 0.0;
            instructionText.scrollFactor.y = 0.0;
            instructionText.alignment = "center";
            add(instructionText);
            scoreText = new FlxText(FlxG.width - 50, 0, 50, "0");
            scoreText.color = textColor;
            scoreText.scrollFactor.x = 0.0;
            scoreText.scrollFactor.y = 0.0;
            add(scoreText);
            highScoreText = new FlxText(10, 0, 50, "HI 0");
            setHighScoreText();
            highScoreText.color = textColor;
            highScoreText.scrollFactor.x = 0.0;
            highScoreText.scrollFactor.y = 0.0;
            add(highScoreText);
        }

        private function nextInstruction():String
        {
            if (FlxG.level < messages.length) {
                return messages[FlxG.level];
            }
            else {
                return "";
            }
        }

        override public function update():void 
        {
            lifeTime += FlxG.elapsed;
            updateInput();
            if ("start" == state 
                    && ((player.velocity.x != 0.0 || player.velocity.y != 0.0)
                    || (player2.velocity.x != 0.0 || player2.velocity.y != 0.0)))
            {
                state = "play";
                instructionText.text = nextInstruction();
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
                map.overlapsWithCallback(player, collideLava);
                map.overlapsWithCallback(player2, collideLava);
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
            FlxG.score += (FlxG.level + 1) * (6000 - Math.round(lifeTime) * 100);
            instructionText.text = "LET'S GET OUT OF HERE!";
            FlxG.fade(0xFFFFFFFF, 4.0, win);
            // FlxG.music.fadeOut(4.0);
            state = "win";
            FlxKongregate.api.stats.submit("Score", FlxG.score);
        }

        private function collideLava(me:FlxObject, you:FlxObject):void
        {
            var tile:FlxTile = FlxTile(me);
            if (tile.index != LAVA || state != "play") {
                return;
            }
            var player:FlxSprite = FlxSprite(you);
            /*
            var my:FlxPoint = new FlxPoint(tile.x + tile.frameWidth / 2, tile.y + tile.frameHeight / 2);
            var yours:FlxPoint = new FlxPoint(player.x + player.frameWidth / 2, player.y + player.frameHeight / 2);
            if (0.5 * (enemy.frameWidth + player.frameWidth) < FlxU.getDistance(my, yours)) {
                // FlxG.log("collide " + FlxU.getDistance(my, yours).toFixed(2));
                return;
            }
            */
            player.hurt(1);
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
            FlxG.level++;
            if (FlxG.levels.length <= FlxG.level) {
                FlxG.level = 0;
            }
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
                instructionText.text = nextInstruction();
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
            if ("lose" == state || "win" == state) {
                return;
            }
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
            if ("lose" == state || "win" == state) {
                return;
            }
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
