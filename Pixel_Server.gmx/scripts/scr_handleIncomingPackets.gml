var buffer = argument[0];
var socket = argument[1];
var msgid = buffer_read(buffer, buffer_u8);

switch (msgid)
{
    case 1: //latency request
        var time = buffer_read(buffer, buffer_u32);//read in the time from the client
        buffer_seek(global.buffer, buffer_seek_start, 0);//seek to the beginning of the read buffer
        buffer_write(global.buffer, buffer_u8, 1);//write a tag to the global write buffer
        buffer_write(global.buffer, buffer_u32, time);//write the time recieved to the global write buffer
        //send back to player that sent this message
        network_send_packet(socket, global.buffer, buffer_tell(global.buffer));
        break;
//=======================================================================================================================
    case 2://registration request
        var pId = buffer_read(buffer, buffer_u32);
        var playerUsername = buffer_read(buffer, buffer_string);
        var passwordHash = buffer_read(buffer, buffer_string);
        var response = 0;
        
        //check if player aleady exists
        ini_open("users.ini");
        var playerExists = ini_read_string("users", playerUsername, "false");
        if (playerExists == "false")
        {
            //register new player
            ini_write_string("users", playerUsername, passwordHash);
            response = 1;
            scr_showNotification("A new player has registered!");
            
            with (obj_player)
            {
                if (playerIdentifier == pId)
                {
                    playerName = playerUsername;
                }
            }
            
        }
        ini_close(); // don't forget to close ini files you open
        
        //send response to the client
        buffer_seek(global.buffer, buffer_seek_start, 0);//seek to the beginning of the read buffer
        buffer_write(global.buffer, buffer_u8, 2);//the tag is 2 for register tag
        buffer_write(global.buffer, buffer_u8, response);//put in if the character name already exists, etc
        network_send_packet(socket, global.buffer, buffer_tell(global.buffer));
        
        break;
//=======================================================================================================================
    case 3://login request
        var pId = buffer_read(buffer, buffer_u32);
        var playerUsername = buffer_read(buffer, buffer_string);
        var passwordHash = buffer_read(buffer, buffer_string);
        var response = 0;
        
        //check if player exists
        ini_open("users.ini");
        var playerStoredPassword = ini_read_string("users", playerUsername, "false");
        if (playerStoredPassword != "false")
        {
            if (passwordHash == playerStoredPassword)
            response = 1;
            
            with (obj_player)
            {
                if (playerIdentifier == pId)
                {
                    playerName = playerUsername;
                }
            }
            
        }
        ini_close();
        
        //send a response
        buffer_seek(global.buffer, buffer_seek_start, 0);//seek to the beginning of the read buffer
        buffer_write(global.buffer, buffer_u8, 3);//the tag is 3 for login tag
        buffer_write(global.buffer, buffer_u8, response);
        network_send_packet(socket, global.buffer, buffer_tell(global.buffer));
        
        break;
        
//=======================================================================================================================
    case 5:  
            
        var pId = buffer_read(buffer, buffer_u32);
            ///Tell other players to delete player model
                for (var i = 0; i < ds_list_size(global.players);i++)
                    {
                        var storedPlayerSocket = ds_list_find_value(global.players, i);
                        
                        if (storedPlayerSocket != socket)
                        {
                            var player = noone;
                            
                            with (obj_player)
                            {
                                if (self.playerSocket == storedPlayerSocket)
                                {
                                    player = id;
                                }
                            }
                            
                            if (player != noone)
                            {
                                    buffer_seek(global.buffer, buffer_seek_start, 0);
                                    buffer_write(global.buffer, buffer_u8, 5);
                                    buffer_write(global.buffer, buffer_u32, pId);
                                    network_send_packet(socket, global.buffer, buffer_tell(global.buffer));  
                            }
                        }
                    }
        break;
//=======================================================================================================================
    case 6:  //create gameworld and press Esc
        var pId = buffer_read(buffer, buffer_u32);
        var type = buffer_read(buffer, buffer_u8);
        var roomId = buffer_read(buffer, buffer_u8);
        var pName = "";
        
        with (obj_player)
        {
            if (playerIdentifier == pId)
                {
                    playerInGame = !playerInGame;
                    pName = playerName;
                    playerType = type;
                }
        }
        
        //tell other players about this change
        //notify all players
        for (var i = 0; i < ds_list_size(global.players);i++)
        {
            var storedPlayerSocket = ds_list_find_value(global.players, i);
            
            if (storedPlayerSocket != socket)
            {
                buffer_seek(global.buffer, buffer_seek_start, 0);
                buffer_write(global.buffer, buffer_u8, 6);
                buffer_write(global.buffer, buffer_u32, pId);
                buffer_write(global.buffer, buffer_u8, type);
                buffer_write(global.buffer, buffer_string, pName);
                network_send_packet(storedPlayerSocket, global.buffer, buffer_tell(global.buffer));   
            }
        }
        
        if (roomId != 0 )
        {
                //tell me about other players
                for (var i = 0; i < ds_list_size(global.players);i++)
                {
                    var storedPlayerSocket = ds_list_find_value(global.players, i);
                    
                    if (storedPlayerSocket != socket)
                    {
                        var player = noone;
                        
                        with (obj_player)
                        {
                            if (self.playerSocket == storedPlayerSocket)
                            {
                                player = id;
                            }
                        }
                        
                        if (player != noone)
                        {
                            if (player.playerInGame)
                            {
                                buffer_seek(global.buffer, buffer_seek_start, 0);
                                buffer_write(global.buffer, buffer_u8, 6);
                                buffer_write(global.buffer, buffer_u32, player.playerIdentifier);
                                buffer_write(global.buffer, buffer_u8, player.playerType);
                                buffer_write(global.buffer, buffer_string, player.playerName);
                                network_send_packet(socket, global.buffer, buffer_tell(global.buffer));  
                            }
                        }
                    }
                }
                
                //tell this player about active NPCs
                for (var i = 0; i < instance_number(obj_npc); i++)
                {
                    var npc = instance_find(obj_npc, i);
                    buffer_seek(global.buffer, buffer_seek_start, 0);
                    buffer_write(global.buffer, buffer_u8, 9);
                    buffer_write(global.buffer, buffer_u32, npc.npcId);
                    buffer_write(global.buffer, buffer_f32, npc.xx);
                    buffer_write(global.buffer, buffer_f32, npc.yy);
                    buffer_write(global.buffer, buffer_u8, npc.npcType);
                    network_send_packet(socket, global.buffer, buffer_tell(global.buffer));
                }
                
                //tell this player about active projectiles
                for (var i = 0; i < instance_number(obj_projectile); i++)
                {
                        var projectile = instance_find(obj_projectile, i);
                        buffer_seek(global.buffer, buffer_seek_start, 0);
                        buffer_write(global.buffer, buffer_u8, 11);
                        buffer_write(global.buffer, buffer_u32, projectile.owner);
                        buffer_write(global.buffer, buffer_u32, projectile.projectileId);
                        buffer_write(global.buffer, buffer_f32, projectile.x);
                        buffer_write(global.buffer, buffer_f32, projectile.y);
                        network_send_packet(storedPlayerSocket, global.buffer, buffer_tell(global.buffer));         
                }
        }
        break;
//=======================================================================================================================
    case 7:  // get player updates // localplayer/step_1
        var pId = buffer_read(buffer, buffer_u32);
        var xx = buffer_read(buffer, buffer_f32);
        var yy = buffer_read(buffer, buffer_f32);
            var hair = buffer_read(buffer, buffer_u16);
            var outfitTop = buffer_read(buffer, buffer_u16);
            var outfitBottom = buffer_read(buffer, buffer_u16);
            var skin = buffer_read(buffer, buffer_u8);
            var diaper = buffer_read(buffer, buffer_u16);
            var colour = buffer_read(buffer, buffer_u32);
            var hairColour = buffer_read(buffer, buffer_u32);
            var outfitTopColour = buffer_read(buffer, buffer_u32);
             var outfitBottomColour = buffer_read(buffer, buffer_u32);
            var xxpeeHold = buffer_read(buffer, buffer_u8);
        var frames = buffer_read(buffer, buffer_u8);
        var dir = buffer_read(buffer, buffer_u8);
        var rooms = buffer_read(buffer, buffer_u32);
        
                //tell other players about this change
        for (var i = 0; i < ds_list_size(global.players);i++)
        {
            var storedPlayerSocket = ds_list_find_value(global.players, i);
            
            if (storedPlayerSocket != socket)
            {
                buffer_seek(global.buffer, buffer_seek_start, 0);
                buffer_write(global.buffer, buffer_u8, 7);
                buffer_write(global.buffer, buffer_u32, pId);
                buffer_write(global.buffer, buffer_f32, xx);
                buffer_write(global.buffer, buffer_f32, yy);
                    buffer_write(global.buffer, buffer_u16, hair);
                    buffer_write(global.buffer, buffer_u16, outfitTop);
                    buffer_write(global.buffer, buffer_u16, outfitBottom);
                        buffer_write(global.buffer, buffer_u8, skin);
                    buffer_write(global.buffer, buffer_u16, diaper);
                    buffer_write(global.buffer, buffer_u32, colour);
                    buffer_write(global.buffer, buffer_u32, hairColour);
                    buffer_write(global.buffer, buffer_u32, outfitTopColour);
                    buffer_write(global.buffer, buffer_u32, outfitBottomColour);
                    buffer_write(global.buffer, buffer_u8, xxpeeHold);
                buffer_write(global.buffer, buffer_u8, frames);
                buffer_write(global.buffer, buffer_u8, dir);
                buffer_write(global.buffer, buffer_u32, rooms);

                network_send_packet(storedPlayerSocket, global.buffer, buffer_tell(global.buffer));   
            }
        }
        break;
//=======================================================================================================================
    case 8: // get chat message  //  obClient press Enter
        var pId = buffer_read(buffer, buffer_u32);
        var text = buffer_read(buffer, buffer_string);
        
        //tell other players about this change
        for (var i = 0; i < ds_list_size(global.players);i++)
        {
            var storedPlayerSocket = ds_list_find_value(global.players, i); //dont send to the client we got this from
            
            if (storedPlayerSocket != socket)
            {
                buffer_seek(global.buffer, buffer_seek_start, 0);
                buffer_write(global.buffer, buffer_u8, 8);
                buffer_write(global.buffer, buffer_u32, pId);
                buffer_write(global.buffer, buffer_string, text);
                network_send_packet(storedPlayerSocket, global.buffer, buffer_tell(global.buffer));   
            }
        }
        break;
//=======================================================================================================================
    case 10:  //gotten from client alarm[1]
        var latency = buffer_read(buffer, buffer_u32);
        var player = noone;
        
        with (obj_player)
        {
            if (self.playerSocket == socket)
            {
                player = id;
            }
        }
        
        if (player != noone)
        {
            player.playerLatency = latency;
        }
        
        // tell all other players about this change
        for (var i = 0; i < ds_list_size(global.players);i++)
        {
            var storedPlayerSocket = ds_list_find_value(global.players, i); //dont send to the client we got this from
            
            if (storedPlayerSocket != socket)
            {
                buffer_seek(global.buffer, buffer_seek_start, 0);
                buffer_write(global.buffer, buffer_u8, 10);
                buffer_write(global.buffer, buffer_u32, player.playerIdentifier);
                buffer_write(global.buffer, buffer_u32, player.playerLatency);
                network_send_packet(storedPlayerSocket, global.buffer, buffer_tell(global.buffer));   
            }
        }
        break;
//=======================================================================================================================
    case 11: // update projectile position  //  projectile step_1
        var pId = buffer_read(buffer, buffer_u32);
        var projectileId = buffer_read(buffer, buffer_u32);
        var xx = buffer_read(buffer, buffer_f32);
        var yy = buffer_read(buffer, buffer_f32);
        
        var projectile = noone;
        
        with (obj_projectile)
        {
            if(self.owner == pId && self.projectileId == projectileId)
            {
                projectile = id;
            }
        }
        
        if (projectile != noone)
        {
            projectile.x = xx;
            projectile.y = yy;
        }
        else
        {
            var p = instance_create(xx, yy, obj_projectile);
            p.owner = pId;
            p.projectileId = projectileId;
        }
        
        // tell all other players about this change
        for (var i = 0; i < ds_list_size(global.players);i++)
        {
            var storedPlayerSocket = ds_list_find_value(global.players, i); //dont send to the client we got this from
            if (storedPlayerSocket != socket)
            {
                var player = noone;
                
                with (obj_player)
                {
                    if (self.playerSocket == storedPlayerSocket)
                    {
                        player = id;
                    }
                    if (player != noone)
                    {
                        if(player.playerInGame)
                        {
                            buffer_seek(global.buffer, buffer_seek_start, 0);
                            buffer_write(global.buffer, buffer_u8, 11);
                            buffer_write(global.buffer, buffer_u32, pId);
                            buffer_write(global.buffer, buffer_u32, projectileId);
                            buffer_write(global.buffer, buffer_f32, xx);
                            buffer_write(global.buffer, buffer_f32, yy);
                            network_send_packet(storedPlayerSocket, global.buffer, buffer_tell(global.buffer));   
                        }
                    }
                }
            }
        }
        break;
//=======================================================================================================================
    case 12:  //from projectile destroy event
        var pId = buffer_read(buffer, buffer_u32);
        var projectileId = buffer_read(buffer, buffer_u32);
        
        with (obj_projectile)
        {
            if(self.owner == pId && self.projectileId == projectileId)
            {
                instance_destroy();
            }
        }
        
        for (var i = 0; i < ds_list_size(global.players);i++)
        {
            var storedPlayerSocket = ds_list_find_value(global.players, i); //dont send to the client we got this from
            
            if (storedPlayerSocket != socket)
            {
                buffer_seek(global.buffer, buffer_seek_start, 0);
                buffer_write(global.buffer, buffer_u8, 12);
                buffer_write(global.buffer, buffer_u32, pId);
                buffer_write(global.buffer, buffer_u32, projectileId);
                network_send_packet(storedPlayerSocket, global.buffer, buffer_tell(global.buffer));   
            }
        }
        
        break;
//=======================================================================================================================
    case 13:  //get ball smack
                //obj_ball.xx = buffer_read(buffer, buffer_f32);
                //obj_ball.yy = buffer_read(buffer, buffer_f32);
                //obj_ball.direction = buffer_read(buffer, buffer_u16)+180;
                var owns = buffer_read(buffer, buffer_u32);
                
                obj_ball.owner = owns;
                
        for (var i = 0; i < ds_list_size(global.players);i++)
            {
                var storedPlayerSocket = ds_list_find_value(global.players, i); //dont send to the client we got this from
                
                if (storedPlayerSocket != socket)
                {
                    buffer_seek(global.buffer, buffer_seek_start, 0);
                    buffer_write(global.buffer, buffer_u8, 13);
                    buffer_write(global.buffer, buffer_u32, owns);
                    network_send_packet(storedPlayerSocket, global.buffer, buffer_tell(global.buffer));   
                }
            }
        
        break;
//=======================================================================================================================
    case 14: //ball position
        var xx = buffer_read(buffer, buffer_f32);
        var yy = buffer_read(buffer, buffer_f32);       
        
        
        for (var i = 0; i < ds_list_size(global.players);i++)
            {
                var storedPlayerSocket = ds_list_find_value(global.players, i); //dont send to the client we got this from
                
                if (storedPlayerSocket != socket)
                {
                    buffer_seek(global.buffer, buffer_seek_start, 0);
                    buffer_write(global.buffer, buffer_u8, 14);
                    buffer_write(global.buffer, buffer_f32, xx);
                    buffer_write(global.buffer, buffer_f32, yy);
                    //buffer_write(global.buffer, buffer_u32, obj_ball.owner);
                    network_send_packet(storedPlayerSocket, global.buffer, buffer_tell(global.buffer));   
                }
            }

        break;

//=======================================================================================================================
    case 15: //save player colors
        var xxplayerUsername = buffer_read(buffer, buffer_string);
        var xxhairCustom = buffer_read(buffer, buffer_u16);
        var xxoutfitTopCustom = buffer_read(buffer, buffer_u16);
            var xxoutfitBottomCustom = buffer_read(buffer, buffer_u16);
        var xxskinCustom = buffer_read(buffer, buffer_u8);
        var xxdiaperCustom = buffer_read(buffer, buffer_u16);
        var xxskinCol = buffer_read(buffer, buffer_u32);
        var xxhairCol = buffer_read(buffer, buffer_u32);
        var xxoutfitTopCol = buffer_read(buffer, buffer_u32);
        var xxoutfitBottomCol = buffer_read(buffer, buffer_u32);
        
        //register new player
        ini_open("userAppearance.ini");
        
        ini_write_string(xxplayerUsername, "hair", xxhairCustom);
        ini_write_string(xxplayerUsername, "outfitTop", xxoutfitTopCustom);
            ini_write_string(xxplayerUsername, "outfitBottom", xxoutfitBottomCustom);
        ini_write_string(xxplayerUsername, "skin", xxskinCustom);
        ini_write_string(xxplayerUsername, "diaper", xxdiaperCustom);
        ini_write_string(xxplayerUsername, "skinColor", xxskinCol);
        ini_write_string(xxplayerUsername, "hairColor", xxhairCol);
        ini_write_string(xxplayerUsername, "outfitTopColor", xxoutfitTopCol);
        ini_write_string(xxplayerUsername, "outfitBottomColor", xxoutfitBottomCol);
        scr_showNotification("Player updated appearance!");
            
        ini_close(); // don't forget to close ini files you open
        
        break;
//=======================================================================================================================
    case 16: // Load character button asking if data exists
        var xxplayerUsername = buffer_read(buffer, buffer_string);
        
        ini_open("userAppearance.ini");
        
        if (ini_section_exists(xxplayerUsername))
            {
            
                var xxhairCustom = ini_read_string(xxplayerUsername, "hair", "false");
                var xxoutfitTopCustom = ini_read_string(xxplayerUsername, "outfitTop", "false");
                    var xxoutfitBottomCustom = ini_read_string(xxplayerUsername, "outfitBottom", "false");
                var xxskinCustom = ini_read_string(xxplayerUsername, "skin", "false");
                var xxdiaperCustom = ini_read_string(xxplayerUsername, "diaper", "false");
                var xxskinCol = ini_read_string(xxplayerUsername, "skinColor", "false");
                var xxhairCol = ini_read_string(xxplayerUsername, "hairColor", "false");
                var xxoutfitTopCol = ini_read_string(xxplayerUsername, "outfitTopColor", "false");
                    var xxoutfitBottomCol = ini_read_string(xxplayerUsername, "outfitBottomColor", "false");
                
            
                 buffer_seek(global.buffer, buffer_seek_start, 0);
                buffer_write(global.buffer, buffer_u8, 16); //tell client what player appearance is
                    buffer_write(global.buffer, buffer_u16, xxhairCustom);
                    buffer_write(global.buffer, buffer_u16, xxoutfitTopCustom);
                        buffer_write(global.buffer, buffer_u16, xxoutfitBottomCustom);
                    buffer_write(global.buffer, buffer_u8, xxskinCustom);
                    buffer_write(global.buffer, buffer_u16, xxdiaperCustom);
                    buffer_write(global.buffer, buffer_u32, xxskinCol);
                    buffer_write(global.buffer, buffer_u32, xxhairCol);
                    buffer_write(global.buffer, buffer_u32, xxoutfitTopCol);
                        buffer_write(global.buffer, buffer_u32, xxoutfitBottomCol);
                network_send_packet(socket, global.buffer, buffer_tell(global.buffer));   
            }
        ini_close(); // don't forget to close ini files you open
        
        
        ini_open("userItems.ini");
            
            if (ini_section_exists(xxplayerUsername))
                {
                    
                    buffer_seek(global.buffer, buffer_seek_start, 0);
                    buffer_write(global.buffer, buffer_u8, 20);
                    
                        var i;
                        i = 25;
                        repeat(25)
                           {
                                var xxItemRead = ini_read_string(xxplayerUsername, i, "false");
                                buffer_write(global.buffer, buffer_u16, xxItemRead);
                                i -= 1;
                           }
                    
                    network_send_packet(socket, global.buffer, buffer_tell(global.buffer));
                }
            
        ini_close(); // don't forget to close ini files you open
        
        break;
//=======================================================================================================================
    case 17: //someone created a puddle
        var xxroom = buffer_read(buffer, buffer_u8);
        var xx = buffer_read(buffer, buffer_f32);
        var yy = buffer_read(buffer, buffer_f32);
        
        for (var i = 0; i < ds_list_size(global.players);i++)
        {
            var storedPlayerSocket = ds_list_find_value(global.players, i); //dont send to the client we got this from
            
            if (storedPlayerSocket != socket)
            {
                buffer_seek(global.buffer, buffer_seek_start, 0);
                buffer_write(global.buffer, buffer_u8, 17);
                buffer_write(global.buffer, buffer_u8, xxroom);
                buffer_write(global.buffer, buffer_f32, xx);
                buffer_write(global.buffer, buffer_f32, yy);
                network_send_packet(storedPlayerSocket, global.buffer, buffer_tell(global.buffer));   
            }
        }
        
        break;
//=======================================================================================================================
    case 18: //derpy NPC test
        
        obj_npc_derpyDragon.npcActive = 30;
        
                buffer_seek(global.buffer, buffer_seek_start, 0);
                buffer_write(global.buffer, buffer_u8, 18);
                buffer_write(global.buffer, buffer_f32, obj_npc_derpyDragon.x);
                buffer_write(global.buffer, buffer_f32, obj_npc_derpyDragon.y);
                //network_send_packet(storedPlayerSocket, global.buffer, buffer_tell(global.buffer));   
                network_send_packet(socket, global.buffer, buffer_tell(global.buffer));   
                
        break;

//=======================================================================================================================

    case 19:  //player saved a new item
        var xxplayerUsername = buffer_read(buffer, buffer_string);
        var savingItemSlot = buffer_read(buffer, buffer_u8);
        var savingItem = buffer_read(buffer, buffer_u16);
        
        ini_open("userItems.ini");
            
            ini_write_string(xxplayerUsername, savingItemSlot, savingItem);
        
        ini_close(); // don't forget to close ini files you open
        
        break;

//=======================================================================================================================
    case 21:  // get player updates // localplayer/step_1
    var pId = buffer_read(buffer, buffer_u32);
    var face_xx = buffer_read(buffer, buffer_u8);
    
            //tell other players about this change
    for (var i = 0; i < ds_list_size(global.players);i++)
    {
        var storedPlayerSocket = ds_list_find_value(global.players, i);
        
        if (storedPlayerSocket != socket)
        {
            buffer_seek(global.buffer, buffer_seek_start, 0);
            buffer_write(global.buffer, buffer_u8, 21);
            buffer_write(global.buffer, buffer_u32, pId);
            buffer_write(global.buffer, buffer_u8, face_xx);

            network_send_packet(storedPlayerSocket, global.buffer, buffer_tell(global.buffer));   
        }
    }
    break;
//=======================================================================================================================
    case 22:  //tell other players that we're typing
        var pId = buffer_read(buffer, buffer_u32);
        var typing_xx = buffer_read(buffer, buffer_u8);
        
                //tell other players about this change
        for (var i = 0; i < ds_list_size(global.players);i++)
        {
            var storedPlayerSocket = ds_list_find_value(global.players, i);
            
            if (storedPlayerSocket != socket)
            {
                buffer_seek(global.buffer, buffer_seek_start, 0);
                buffer_write(global.buffer, buffer_u8, 22);
                buffer_write(global.buffer, buffer_u32, pId);
                buffer_write(global.buffer, buffer_u8, typing_xx);
    
                network_send_packet(storedPlayerSocket, global.buffer, buffer_tell(global.buffer));   
            }
        }
    break;
//=======================================================================================================================
    case 23: //tell time when player asks
        buffer_seek(global.buffer, buffer_seek_start, 0);
        buffer_write(global.buffer, buffer_u8, 23);
        buffer_write(global.buffer, buffer_s8, hours);
        network_send_packet(socket, global.buffer, buffer_tell(global.buffer));
    break;
//=======================================================================================================================
//=======================================================================================================================
//=======================================================================================================================
//=======================================================================================================================
//=======================================================================================================================
//=======================================================================================================================
//=======================================================================================================================
//=======================================================================================================================
//=======================================================================================================================
//=======================================================================================================================
//=======================================================================================================================
//=======================================================================================================================
//=======================================================================================================================
//=======================================================================================================================
//=======================================================================================================================
}
