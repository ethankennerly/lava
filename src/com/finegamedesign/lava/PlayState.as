package com.finegamedesign.lava
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.geom.Matrix;

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
        [Embed(source="../../../../gfx/maze_move.png")]
        private static const MazeMove:Class;
        [Embed(source="../../../../gfx/maze_path.png")]
        private static const MazePath:Class;
        [Embed(source="../../../../gfx/maze_lava.png")]
        private static const MazeLava:Class;
        [Embed(source="../../../../gfx/maze20x15_0.png")]
        private static const Maze20x15_0:Class;
        [Embed(source="../../../../gfx/maze20x15_1.png")]
        private static const Maze20x15_1:Class;
        [Embed(source="../../../../gfx/maze20x15.png")]
        private static const Maze20x15:Class;
        [Embed(source="../../../../gfx/maze40x30.png")]
        private static const Maze40x30:Class;
        [Embed(source="../../../../gfx/maze40x30_1.png")]
        private static const Maze40x30_1:Class;
        [Embed(source="../../../../gfx/maze40x30_2.png")]
        private static const Maze40x30_2:Class;
        /**
         * Swap 20x15 maps 0 and 1.  2013-11-02 Ian Hill may expect path through center before path around edge.
         * Maze40x30_1 copied with lava near spawn points.  2013-11-02 Ian Hill expects need to move both.
         * Maze40x30_2 parallel and branching.  2013-11-03 Ian Hill expects parallel maze. 2013-11-03 Ian Hill expects branching maze.
         * http://www.youtube.com/watch?v=mKbeWHey06I&feature=youtu.be
         */
        private static var maps:Array = [MazeMove,
                                         // Maze40x30_2,  // test
                                         MazePath,
                                         MazeLava,
                                         Maze20x15_0,
                                         Maze20x15_1,
                                         Maze20x15,
                                         Maze40x30,
                                         Maze40x30_1,
                                         Maze40x30_2 ];
        [Embed(source="../../../../gfx/tiles.png")]
        private static const Tiles:Class;
        [Embed(source="../../../../gfx/palette.png")]
        private static const Palette:Class;
        private static var textColor:uint = 0xFFFFFF;
        private static var messages:Array = [
            "PRESS ARROW KEYS OR WASD\nTO MEET YOUR PARTNER",
            "PRESS ARROW KEYS OR WASD\nTO MOVE AROUND WALLS",
            "MEET YOUR PARTNER!\nAVOID RED LAVA!",
            "QUICK!  MEET YOUR PARTNER!\nAVOID RED LAVA!",
            "FOR HIGH SCORE, MEET QUICKLY.",
            "FOR MAX SCORE, MOVE BOTH PARTNERS.",
            "TOO HARD? MOVE BOTH PARTNERS: WASD & ARROWS",
            "IMPOSSIBLE? MOVE BOTH PARTNERS: WASD & ARROWS" ];
        private static var cheated:Boolean = false;

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
        private var started:Boolean;

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
            addHud(FlxG.camera.zoom <= 1 ? 0 : 120);
            state = "play";
            started = false;
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
            randomlyFlip(image.bitmapData);
            map.loadMap(FlxTilemap.bitmapToCSV(image.bitmapData), Tiles,
                WIDTH, WIDTH, FlxTilemap.OFF, 0, 0, 1);
            zoom(map);
            center(map);
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
                    placePlayer(player, map, p);
                }
                else if (palettePixels[PLAYER2] == pixels[p]) {
                    // map.setTileByIndex(p, PLAYER2);
                    player2 = new Player2();
                    placePlayer(player2, map, p);
                }
            }
            add(map);
        }

        private function zoom(map:FlxTilemap, maxWidthInTiles:int=20):void
        {
            if (map.widthInTiles <= maxWidthInTiles) {
                FlxG.camera.zoom = 2;
            }
            else {
                FlxG.camera.zoom = 1;
            }
        }

        private function randomlyFlip(bitmapData:BitmapData):void
        {
            FlxG.random() < 0.5 ? flipBitmapData(bitmapData, "x") : null;
            FlxG.random() < 0.5 ? flipBitmapData(bitmapData, "y") : null;
            FlxG.random() < 0.5 ? flipBitmapData(bitmapData, "180") : null;
        }

        // Copied from http://stackoverflow.com/questions/7773488/flipping-a-bitmap-horizontally
        private function flipBitmapData(original:BitmapData, axis:String = "x"):void
        {
             var flipped:BitmapData = new BitmapData(original.width, original.height, true, 0);
             var matrix:Matrix
             if(axis == "x"){
                  matrix = new Matrix( -1, 0, 0, 1, original.width, 0);
             } else if (axis == "y") {
                  matrix = new Matrix( 1, 0, 0, -1, 0, original.height);
             }
             else if (axis == "180") {
                  matrix = new Matrix( -1, 0, 0, -1, 0, original.height);
             }
             flipped.draw(original, matrix, null, null, null, true);
             original.draw(flipped);
        }

        private function center(map:FlxTilemap):void
        {
            map.x = Math.round((FlxG.width - WIDTH * map.widthInTiles) / 2);
            map.y = Math.round((FlxG.height - WIDTH * map.heightInTiles) / 2);
        }

        private function placePlayer(player:Player, map:FlxTilemap, p:int):void
        {
            player.y = WIDTH * int(p / map.widthInTiles)
                + player.frameHeight / 2 + map.y;
            player.x = WIDTH * (p % map.widthInTiles)
                + player.frameWidth / 2 + map.x;
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

        private function addHud(margin:int):void
        {
            var titleMessage:String;
            if (0 == FlxG.level) {
                titleMessage = "LAVA  MAZE" 
                    + "\nFor  one or two players"
                    + "\n\n\n\n\n\n\n\n\n\n\n\n\n\nOne-day game by Ethan Kennerly"
                    + "\nPlaytesting by Ian Hill, Jennifer Russ"
                    + "\n\nFor The Arbitrary Game Jam #4  on November 2, 2013."
                    + "\nTAG4 themes:  Lava & Love hurts & Be a stranger to fear";
            }
            else {
                titleMessage = "";

            }
            titleText = new FlxText(0, margin + 32, FlxG.width, titleMessage); 
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
            instructionText = new FlxText(0, margin, FlxG.width, instructionMessage);
            instructionText.color = textColor;
            instructionText.scrollFactor.x = 0.0;
            instructionText.scrollFactor.y = 0.0;
            instructionText.alignment = "center";
            add(instructionText);
            scoreText = new FlxText(FlxG.width - margin - 100, margin, 50, "0");
            scoreText.color = textColor;
            scoreText.scrollFactor.x = 0.0;
            scoreText.scrollFactor.y = 0.0;
            add(scoreText);
            highScoreText = new FlxText(50 + margin, margin, 100, "HI 0");
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
            if (!started
                    && ((player.velocity.x != 0.0 || player.velocity.y != 0.0)
                    || (player2.velocity.x != 0.0 || player2.velocity.y != 0.0)))
            {
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
            if (!cheated) {
                FlxG.score += (FlxG.level + 1) * Math.max(1000, (6000 - Math.round(lifeTime) * 100));
                FlxKongregate.api.stats.submit("Score", FlxG.score);
            }
            instructionText.text = "LET'S GET OUT OF HERE!";
            FlxG.play(Sounds.pickup);
            FlxG.fade(0xFFFFFFFF, 2.0, win);
            // FlxG.music.fadeOut(4.0);
            state = "win";
        }

        /**
         * TODO: Do not move. Lava enters tile. Ian Hill expects game over.
         * http://www.youtube.com/watch?v=mKbeWHey06I
         */
        private function collideLava(me:FlxObject, you:FlxObject):void
        {
            var tile:FlxTile = FlxTile(me);
            if (tile.index != LAVA || (state != "play")) {
                return;
            }
            var player:FlxSprite = FlxSprite(you);
            if (!player.solid) {
                return;
            }
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
                    cheated = true;
                    FlxG.timeScale *= 0.5;
                }
                else if (FlxG.keys.justPressed("NINE")) {
                    cheated = true;
                    player.solid = !player.solid;
                    player2.solid = !player2.solid;
                    player2.health = player2.health <= 1 ? int.MAX_VALUE : 1;
                    player2.health = player2.health <= 1 ? int.MAX_VALUE : 1;
                    player.alpha = 0.5 + (player.health <= 1 ? 0.5 : 0.0);
                    player2.alpha = 0.5 + (player2.health <= 1 ? 0.5 : 0.0);
                }
            }
        }
    }
}
