
        ScriptHost:LoadScript("scripts/autotracking/item_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/location_mapping.lua")

CUR_INDEX = -1
--SLOT_DATA = nil

SLOT_DATA = {}

function has_value (t, val)
    for i, v in ipairs(t) do
        if v == val then return 1 end
    end
    return 0
end

function dump_table(o, depth)
    if depth == nil then
        depth = 0
    end
    if type(o) == 'table' then
        local tabs = ('	'):rep(depth)
        local tabs2 = ('	'):rep(depth + 1)
        local s = '{
'
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. tabs2 .. '[' .. k .. '] = ' .. dump_table(v, depth + 1) .. ',
'
        end
        return s .. tabs .. '}'
    else
        return tostring(o)
    end
end


function onClear(slot_data)
    --SLOT_DATA = slot_data
    CUR_INDEX = -1
    -- reset locations
    for _, location_array in pairs(LOCATION_MAPPING) do
        for _, location in pairs(location_array) do
            if location then
                local location_obj = Tracker:FindObjectForCode(location)
                if location_obj then
                    if location:sub(1, 1) == "@" then
                        location_obj.AvailableChestCount = location_obj.ChestCount
                    else
                        location_obj.Active = false
                    end
                end
            end
        end
    end
    -- reset items
    for _, item in pairs(ITEM_MAPPING) do
        for _, item_code in pairs(item[1]) do
            if item_code and item[2] then
                local item_obj = Tracker:FindObjectForCode(item_code)
                if item_obj then
                    if item[2] == "toggle" then
                        item_obj.Active = false
                    elseif item[2] == "progressive" then
                        item_obj.CurrentStage = 0
                        item_obj.Active = false
                    elseif item[2] == "consumable" then
                        if item_obj.MinCount then
                            item_obj.AcquiredCount = item_obj.MinCount
                        else
                            item_obj.AcquiredCount = 0
                        end
                    elseif item[2] == "progressive_toggle" then
                        item_obj.CurrentStage = 0
                        item_obj.Active = false
                    end
                end
            end
        end
    end
    PLAYER_ID = Archipelago.PlayerNumber or -1
    TEAM_NUMBER = Archipelago.TeamNumber or 0
    SLOT_DATA = slot_data
    -- if Tracker:FindObjectForCode("autofill_settings").Active == true then
    --     autoFill(slot_data)
    -- end
    -- bossShuffle()
end

function onItem(index, item_id, item_name, player_number)
    if index <= CUR_INDEX then
        return
    end
    local is_local = player_number == Archipelago.PlayerNumber
    CUR_INDEX = index;
    local item = ITEM_MAPPING[item_id]
    if not item or not item[1] then
        --print(string.format("onItem: could not find item mapping for id %s", item_id))
        return
    end
    for _, item_code in pairs(item[1]) do
        -- print(item[1], item[2])
        local item_obj = Tracker:FindObjectForCode(item_code)
        if item_obj then
            if item_obj.Type == "toggle" then
                -- print("toggle")
                item_obj.Active = true
            elseif item[2] == "progressive" then
                -- print("progressive")
                item_obj.Active = true
            elseif item[2] == "consumable" then
                -- print("consumable")
                item_obj.AcquiredCount = item_obj.AcquiredCount + item_obj.Increment
            elseif item[2] == "progressive_toggle" then
                -- print("progressive_toggle")
                if item_obj.Active then
                    item_obj.CurrentStage = item_obj.CurrentStage + 1
                else
                    item_obj.Active = true
                end
            end
        else
            print(string.format("onItem: could not find object for code %s", item_code[1]))
        end
    end
    canFinish()
    calcHeartpieces()
end

--called when a location gets cleared
function onLocation(location_id, location_name)
    local location_array = LOCATION_MAPPING[location_id]
    if not location_array or not location_array[1] then
        print(string.format("onLocation: could not find location mapping for id %s", location_id))
        return
    end

    for _, location in pairs(location_array) do
        local location_obj = Tracker:FindObjectForCode(location)
        -- print(location, location_obj)
        if location_obj then
            if location:sub(1, 1) == "@" then
                location_obj.AvailableChestCount = location_obj.AvailableChestCount - 1
            else
                location_obj.Active = true
            end
        else
            print(string.format("onLocation: could not find location_object for code %s", location))
        end
    end
    canFinish()
end

function onEvent(key, value, old_value)
    updateEvents(value)
end

function onEventsLaunch(key, value)
    updateEvents(value)
end

-- function autoFill()
--     if SLOT_DATA == nil  then
--         print("its fucked")
--         return
--     end
--     -- print(dump_table(SLOT_DATA))

--     mapToggle={[0]=0,[1]=1,[2]=1,[3]=1,[4]=1}
--     mapToggleReverse={[0]=1,[1]=0,[2]=0,[3]=0,[4]=0}
--     mapTripleReverse={[0]=2,[1]=1,[2]=0}
--     mapDungeonItem={[0]=false,[1]=true,[2]=true,[3]=true,[4]=true,[6]=true}

--     -- mapGlitches={[0]=0,[1]=2,[2]=3,[3]=0,[4]=0}
--     -- progressive={[]=,}
--     mapMode={["open"]=0,["inverted"]=1,["standard"]=2}
--     mapGoals={["crystals"]=0,["ganon"]=1,["bosses"]=2,["pedestal"]=3,["ganonpedestal"]=4,["triforcehunt"]=5,["ganontriforcehunt"]=6,["icerodhunt"]=7,["localtriforcehunt"]=5,["localganontriforcehunt"]=6}
--     mapDark={["none"]=0,["lamp"]=1,["scornes"]=2} -- none=dark room, lamp=vanilla, scornes = firerod
--     mapMedalion={["Bombos"]="bombos",["Ether"]="ether",["Quake"]="quake"}
--     -- retro_caves={[]=}
--     mapBosses={[0]=0,[1]=1,[2]=1,[3]=1,[4]=2}
--     mapEnemizer={[0]=false,[1]=true,[2]=true}
--     -- shop_shuffle={[]=,}


--     slotCodes = {
--         -- glitches_required={code="glitches", mapping=mapToggleReverse},
--         key_drop_shuffle={code="key_drop_shuffle", mapping=mapDungeonItem},
--         pot_shuffle={code="key_drop_shuffle", mapping=mapDungeonItem},
--         dark_room_logic={code="dark_mode", mapping=mapDark},
--         bigkey_shuffle={code="big_keys", mapping=mapDungeonItem},
--         smallkey_shuffle={code="small_keys", mapping=mapToggle},
--         map_shuffle={code="map", mapping=mapDungeonItem},
--         compass_shuffle={code="compass", mapping=mapDungeonItem},
--         -- progressive={code="progressive_items", mapping=mapToggle},
--         goal={code="goal", mapping=mapGoals},
--         crystals_needed_for_gt={code="gt_access", mapping=nil},
--         crystals_needed_for_ganon={code="ganon_killable", mapping=nil},
--         mode={code="start_option", mapping=mapMode},
--         -- retro_bow={code="", mapping=mapToggleReverse},
--         retro_caves={code="retro_caves", mapping=mapDungeonItem},
--         swordless={code="swordless", mapping=mapDungeonItem},
--         -- item_pool={code="", mapping=mapToggle},
--         me_medallion={code="", mapping=mapMedalion},
--         tr_medallion={code="", mapping=mapMedalion},
--         boss_shuffle={code="boss_shuffle", mapping=mapBosses},
--         enemy_shuffle={code="enemizer", mapping=mapEnemizer},
--         shop_shuffle={code="shop_sanity", mapping=nil},
--         triforce_pieces_required={code="triforce_pieces_needed", mapping=nil}
--         -- glitch_boots={code="glitches", mapping=nil}
--     }
--     -- print(dump_table(SLOT_DATA))
--     -- print(Tracker:FindObjectForCode("autofill_settings").Active)
--     if Tracker:FindObjectForCode("autofill_settings").Active == true then
--         for settings_name , settings_value in pairs(SLOT_DATA) do
--             -- print(k, v)
--             if settings_name == "crystals_needed_for_gt" 
--             or settings_name == "crystals_needed_for_ganon" 
--             or settings_name == "triforce_pieces_required" then
--                 Tracker:FindObjectForCode(slotCodes[settings_name].code).AcquiredCount = settings_value
--             elseif settings_name == "shop_shuffle" then
--                 item = Tracker:FindObjectForCode(slotCodes[settings_name].code)
--                 if settings_value ~= "none" then
--                     item.Active = true
--                 elseif settings_value == "none" then
--                     item.Active = false
--                 end
--             elseif settings_name == "shop_item_slots" then
--                 Tracker:FindObjectForCode("shop_sanity").AcquiredCount = settings_value 
--                 Tracker:FindObjectForCode("shop_sanity").Active = true
--             elseif slotCodes[settings_name] then
--                 item = Tracker:FindObjectForCode(slotCodes[settings_name].code)
--                 if item.Type == "toggle" then
--                     item.Active = slotCodes[settings_name].mapping[settings_value]
--                 else 
--                     -- print(k,v,Tracker:FindObjectForCode(slotCodes[k].code).CurrentStage, slotCodes[k].mapping[v])
--                     item.CurrentStage = slotCodes[settings_name].mapping[settings_value]
--                 end
--             end
--         end
--         if SLOT_DATA["mm_medalion"] == SLOT_DATA["tr_medalion"] then
--             Tracker:FindObjectForCode(string.lower(SLOT_DATA["mm_medalion"])).CurrentStage = 3
--         else
--             Tracker:FindObjectForCode(string.lower(SLOT_DATA["mm_medalion"])).CurrentStage = 2
--             Tracker:FindObjectForCode(string.lower(SLOT_DATA["tr_medalion"])).CurrentStage = 1
--         end

--     end
-- end


-- ScriptHost:AddWatchForCode("settings autofill handler", "autofill_settings", autoFill)
Archipelago:AddClearHandler("clear handler", onClear)
Archipelago:AddItemHandler("item handler", onItem)
Archipelago:AddLocationHandler("location handler", onLocation)
