int dropper_weapon_box_counter = 0;
int dropper_weapon_box_counter_max = 300;
array<EHandle> AmmoBox(dropper_weapon_box_counter_max);
dictionary g_Players;

void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor( "Cubemath | Gaftherman" );
    g_Module.ScriptInfo.SetContactInfo( "https://github.com/CubeMath | https://github.com/Gaftherman" );
    
    g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSayDropper );

    g_Scheduler.SetInterval( "ThinkDropper", 0.0f, g_Scheduler.REPEAT_INFINITE_TIMES);
}

void MapInit()
{
    RegisterCustomWeaponBox();
}

void MapActivate()
{
    AmmoBox.resize(0);

    for( int i = 0; i < dropper_weapon_box_counter_max; i++ )
    {
        CBaseEntity@ pHideAmmo = g_EntityFuncs.Create( "env_render_individual", Vector(WORLD_BOUNDARY, WORLD_BOUNDARY, WORLD_BOUNDARY), g_vecZero, false );
        pHideAmmo.pev.target = "dropper_weaponbox_" + i;
        pHideAmmo.pev.targetname = "dropper_weaponbox_" + i + "_render";
        pHideAmmo.pev.spawnflags = (1 | 4 | 8 | 64);
        pHideAmmo.pev.rendermode = 1;
        pHideAmmo.pev.renderamt = 0;
    }
}

class HideAmmoArgument
{
    int HideAmmoArgument = 0;
    bool FirstArgument = false;
    bool SecondaryArgument = false;
}

HideAmmoArgument@ GetPlayerDropperData( CBasePlayer@ pPlayer )
{
    string SteamID = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );

    if( !g_Players.exists( SteamID ) )
    {
        HideAmmoArgument HideAmmoArgument;
        g_Players[SteamID] = HideAmmoArgument;
    }

    return cast<HideAmmoArgument@>( g_Players[SteamID] );
}

void ThinkDropper()
{
    for(int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(iPlayer);

        if(pPlayer is null || !pPlayer.IsConnected())
            continue;

        HideAmmoArgument@ pData = GetPlayerDropperData( pPlayer );

        if( pData.FirstArgument && pData.HideAmmoArgument == 1 && AmmoBox.length() > 0 )
        {
            for( uint i = 0; i < AmmoBox.length(); ++i )
            { 
                if( AmmoBox[i].GetEntity() !is null ) 
                {
                    CBaseEntity@ pFindBoxRender = g_EntityFuncs.FindEntityByTargetname( pFindBoxRender, string(AmmoBox[i].GetEntity().pev.targetname) + "_render" );

                    if( pFindBoxRender !is null )
                        pFindBoxRender.Use(pPlayer, pPlayer, USE_ON);
                }
            }

            pData.FirstArgument = false;
        }

        if( pData.SecondaryArgument && pData.HideAmmoArgument == 0 && AmmoBox.length() > 0 )
        {
            for( uint i = 0; i < AmmoBox.length(); ++i )
            { 
                if( AmmoBox[i].GetEntity() !is null ) 
                {
                    CBaseEntity@ pFindBoxRender = g_EntityFuncs.FindEntityByTargetname( pFindBoxRender, string(AmmoBox[i].GetEntity().pev.targetname) + "_render" );

                    if( pFindBoxRender !is null )
                        pFindBoxRender.Use(pPlayer, pPlayer, USE_OFF);
                }
            }

            pData.SecondaryArgument = false;
        }
    }
}

HookReturnCode ClientSayDropper(SayParameters@ pParams)
{
    CBasePlayer@ pPlayer = pParams.GetPlayer();
    const CCommand@ pArguments = pParams.GetArguments();
    HideAmmoArgument@ pData = GetPlayerDropperData( pPlayer );

    if( pArguments[0].ToUppercase() == "HIDEDROPAMMO" )
    {
        if( pArguments[1].ToUppercase() == "" )
        {
            pData.HideAmmoArgument = (pData.HideAmmoArgument == 1) ? 0 : 1;

            pData.FirstArgument = (pData.HideAmmoArgument == 1) ? true : false;
            pData.SecondaryArgument = (pData.HideAmmoArgument == 0) ? true : false;

            g_Players[g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() )] = pData;
        }

        if( atoi(pArguments[1]) == 1 )
        {
            pData.HideAmmoArgument = 1;
            pData.FirstArgument = true;
        }

        if( atoi(pArguments[1]) == 0 )
        {
            pData.HideAmmoArgument = 0;
            pData.SecondaryArgument = true;
        }

        pParams.ShouldHide = true;

        return HOOK_HANDLED;
    }

    if( pArguments[0].ToUppercase() == "DROPAMMO" )
    {
        string WeaponName;   
        string PrimaryAmmoName;
        string SecondaryAmmoName;

        int PrimaryAmmoIndex;
        int SecondaryAmmoIndex;

        int PrimaryAmmoType;
        int SecondaryAmmoType;

        int WeaponiFlags;

        if( pPlayer.m_hActiveItem.GetEntity() !is null ) 
        {
            CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pPlayer.m_hActiveItem.GetEntity() );

            if( pWeapon !is null )
            {
                WeaponName = pWeapon.pszName();
                PrimaryAmmoName = pWeapon.pszAmmo1();
                SecondaryAmmoName = pWeapon.pszAmmo2();
                
                PrimaryAmmoIndex = pWeapon.PrimaryAmmoIndex();
                SecondaryAmmoIndex = pWeapon.SecondaryAmmoIndex();

                PrimaryAmmoType = pWeapon.m_iPrimaryAmmoType;
                SecondaryAmmoType = pWeapon.m_iSecondaryAmmoType;

                WeaponiFlags = pWeapon.iFlags();
            }
        }

        int PrimaryAmmoDropArg = atoi( pArguments[1] );
        int SecondaryAmmoDropArg = atoi( pArguments[2] );

        int PrimaryAmmoInvetoryOld = ( !PrimaryAmmoName.IsEmpty() ) ? pPlayer.AmmoInventory( PrimaryAmmoIndex ) : -1;
        int SecondaryAmmoInvetoryOld = ( !SecondaryAmmoName.IsEmpty() ) ? pPlayer.AmmoInventory( SecondaryAmmoIndex ) : -1;

        int PrimaryAmmoInvetoryNew = 0;
        int SecondaryAmmoInvetoryNew = 0;

        if( PrimaryAmmoName != "" && PrimaryAmmoName != "Hornets" && PrimaryAmmoIndex > 0 )
        {
            if( PrimaryAmmoDropArg < 1 )
            {
                PrimaryAmmoInvetoryNew = pPlayer.AmmoInventory( PrimaryAmmoIndex );
                PrimaryAmmoInvetoryNew = PrimaryAmmoInvetoryNew - PrimaryAmmoInvetoryNew * 9/10;
            }
            else
            {
                if( PrimaryAmmoDropArg > PrimaryAmmoInvetoryOld ) 
                    PrimaryAmmoDropArg = PrimaryAmmoInvetoryOld;

                PrimaryAmmoInvetoryNew = PrimaryAmmoDropArg;
            }
            pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex(PrimaryAmmoName), PrimaryAmmoInvetoryOld - PrimaryAmmoInvetoryNew );
        }

        if( SecondaryAmmoName != "" && SecondaryAmmoIndex > 0)
        {
            if( SecondaryAmmoDropArg < 1 )
            {
                SecondaryAmmoInvetoryNew = pPlayer.AmmoInventory( SecondaryAmmoIndex );
                SecondaryAmmoInvetoryNew = SecondaryAmmoInvetoryNew - SecondaryAmmoInvetoryNew * 9/10;
            }
            else
            {
                if( SecondaryAmmoDropArg > SecondaryAmmoInvetoryOld ) 
                    SecondaryAmmoDropArg = SecondaryAmmoInvetoryOld;
                    
                SecondaryAmmoInvetoryNew = SecondaryAmmoDropArg;
            }
            pPlayer.m_rgAmmo( SecondaryAmmoIndex, SecondaryAmmoInvetoryOld - SecondaryAmmoInvetoryNew );
        }

        if( PrimaryAmmoInvetoryNew > 0 || SecondaryAmmoInvetoryNew > 0 )
        {
            string DropperName = "dropper_weaponbox_" + dropper_weapon_box_counter;
            array<string> Names(4);
            array<int> Ammunitions(2);
            array<int> AmmoIndexes(2);
            array<int> Types(2);
            
            CBaseEntity@ pFindBox = g_EntityFuncs.FindEntityByTargetname( pFindBox, DropperName );

            if( pFindBox !is null )
                g_EntityFuncs.Remove( pFindBox );
            
            CBaseEntity@ pWeaponBox = g_EntityFuncs.Create( "custom_weaponbox", pPlayer.pev.origin, pPlayer.pev.angles, false );
            pWeaponBox.pev.targetname = DropperName;
            pWeaponBox.pev.spawnflags = 1024;
            pWeaponBox.pev.rendermode = 1;
            pWeaponBox.pev.renderamt = 255;
            pWeaponBox.pev.origin.z = pWeaponBox.pev.origin.z - 16.0f;
            pWeaponBox.pev.velocity.x = cos(pPlayer.pev.angles.y/180.0f*3.1415927f) * cos(pPlayer.pev.angles.x/60.0f*3.1415927f) * 160.0f;
            pWeaponBox.pev.velocity.y = sin(pPlayer.pev.angles.y/180.0f*3.1415927f) * cos(pPlayer.pev.angles.x/60.0f*3.1415927f) * 160.0f;
            pWeaponBox.pev.velocity.z = sin(pPlayer.pev.angles.x/60.0f*3.1415927f) * 160.0f + 160.0f;
            AmmoBox.insertLast( pWeaponBox );

            if( pData.HideAmmoArgument == 1 )
            {
                CBaseEntity@ pFindBoxRender = g_EntityFuncs.FindEntityByTargetname( pFindBoxRender, DropperName+"_render" );
                pFindBoxRender.Use(pPlayer, pPlayer, USE_ON);
            }

            Names[0] = DropperName;
            Names[1] = WeaponName;
            Names[2] = PrimaryAmmoName;
            Names[3] = SecondaryAmmoName;

            Ammunitions[0] = PrimaryAmmoInvetoryNew;
            Ammunitions[1] = SecondaryAmmoInvetoryNew;

            AmmoIndexes[0] = PrimaryAmmoIndex;
            AmmoIndexes[1] = SecondaryAmmoIndex;

            Types[0] = PrimaryAmmoType;
            Types[1] = SecondaryAmmoType;
            
            g_Scheduler.SetTimeout( "AmmoHandling", 0.01, Names, Ammunitions, AmmoIndexes, Types, WeaponiFlags );
            
            dropper_weapon_box_counter++;

            if( dropper_weapon_box_counter >= dropper_weapon_box_counter_max ) 
                dropper_weapon_box_counter = 0;
        }
        
        pParams.ShouldHide = true;

        return HOOK_HANDLED;
    }

    return HOOK_CONTINUE;
}

void AmmoHandling( array<string>@ Names, array<int>@ Ammunitions, array<int>@ AmmoIndexes, array<int>@ Types, int WeaponiFlags )
{
    CBaseEntity@ pWeaponBox = g_EntityFuncs.FindEntityByTargetname( pWeaponBox, Names[0] );

    if( pWeaponBox !is null ) 
    {
        custom_weaponbox@ pCustomWeaonBox = cast<custom_weaponbox@>( CastToScriptClass( pWeaponBox ) );

        pCustomWeaonBox.WeaponName = Names[1];

        if( Ammunitions[0] > 0 )
        {
            pCustomWeaonBox.PrimaryAmmoName = Names[2];
            pCustomWeaonBox.PrimaryAmmoValue = Ammunitions[0];
        }

        if( Ammunitions[1] > 0 ) 
        {
            pCustomWeaonBox.SecondaryAmmoName = Names[3];
            pCustomWeaonBox.SecondayAmmoValue = Ammunitions[1];
        }

        pCustomWeaonBox.PrimaryAmmoIndex = ( !Names[2].IsEmpty() ) ? AmmoIndexes[0] : -1;
        pCustomWeaonBox.SecondaryAmmoIndex = ( !Names[3].IsEmpty() ) ? AmmoIndexes[1] : -1;

        pCustomWeaonBox.PrimaryAmmoType = Types[0];
        pCustomWeaonBox.SecondaryAmmoType = Types[1];

        pCustomWeaonBox.WeaponiFlags = WeaponiFlags;
    }
}

class custom_weaponbox : ScriptBasePlayerItemEntity
{
    string WeaponName;
    string PrimaryAmmoName;
    string SecondaryAmmoName;

    int PrimaryAmmoValue;
    int SecondayAmmoValue;

    int PrimaryAmmoIndex;
    int SecondaryAmmoIndex;

    int PrimaryAmmoType;
    int SecondaryAmmoType;

    int WeaponiFlags;

    void Spawn()
    {
        self.Precache();

        self.pev.movetype = MOVETYPE_TOSS;
        self.pev.solid = SOLID_TRIGGER;

        g_EntityFuncs.SetModel( self, "models/w_weaponbox.mdl" );

        BaseClass.Spawn();
    }

    void Precache()
    {
        g_Game.PrecacheModel( "models/w_weaponbox.mdl" );
        g_SoundSystem.PrecacheSound( "items/gunpickup2.wav" );

        BaseClass.Precache();
    }

    void Touch( CBaseEntity@ pOther )
    {
        if( pOther is null || !pOther.IsPlayer() || !pOther.IsAlive() || !self.pev.FlagBitSet( FL_ONGROUND ) )
            return;
                
        PackAmmo( cast<CBasePlayer@>( pOther ) );
    }

    void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
    {
        if( pActivator is null || !pActivator.IsPlayer() || !pActivator.IsAlive() || !self.pev.FlagBitSet( FL_ONGROUND ) )
            return;

        PackAmmo( cast<CBasePlayer@>( pActivator ) );
    }

    void PackAmmo( CBasePlayer@ pPlayer )
    {
        if( pPlayer !is null )
        {
            bool VerifyPrimaryAmmmo = ( pPlayer.AmmoInventory( PrimaryAmmoIndex ) == -1 && pPlayer.GetMaxAmmo( PrimaryAmmoName ) == -1 ) ? true : pPlayer.AmmoInventory( PrimaryAmmoIndex ) != pPlayer.GetMaxAmmo( PrimaryAmmoName );
            bool VerifySecondaryAmmo = ( pPlayer.AmmoInventory( SecondaryAmmoIndex ) == -1 && pPlayer.GetMaxAmmo( SecondaryAmmoName ) == -1 ) ? true : pPlayer.AmmoInventory( SecondaryAmmoIndex ) != pPlayer.GetMaxAmmo( SecondaryAmmoName );
            
            if( VerifyPrimaryAmmmo && VerifySecondaryAmmo )
            {
                if( WeaponiFlags & ITEM_FLAG_EXHAUSTIBLE != 0 )
                {    
                    if( pPlayer.HasNamedPlayerItem( WeaponName ) !is null ) 
                    {
                        CBasePlayerItem@ pItem = pPlayer.HasNamedPlayerItem( WeaponName );   

                        if( pItem is null )
                            pPlayer.RemovePlayerItem( pItem );

                        CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>(pItem);

                        PrimaryAmmoType = ( PrimaryAmmoType != -1 ) ? pPlayer.m_rgAmmo( PrimaryAmmoType ) : 0;
                        PrimaryAmmoIndex = ( PrimaryAmmoIndex != -1 ) ? pPlayer.AmmoInventory( PrimaryAmmoIndex ) : 0;

                        SecondaryAmmoType = ( SecondaryAmmoType != -1 ) ? pPlayer.m_rgAmmo( SecondaryAmmoType ) : 0;
                        SecondaryAmmoIndex = ( SecondaryAmmoIndex != -1 ) ? pPlayer.AmmoInventory( SecondaryAmmoIndex ) : 0;

                        if( VerifyAmmo( pPlayer, PrimaryAmmoType, PrimaryAmmoIndex ) && pWeapon.m_iClip <= 0 && VerifyAmmo( pPlayer, SecondaryAmmoType, SecondaryAmmoIndex ) && pWeapon.m_iClip2 <= 0 )
                            pPlayer.RemovePlayerItem( pItem );
                    }   

                    if( pPlayer.HasNamedPlayerItem( WeaponName ) is null )
                    {
                        PrimaryAmmoType = ( PrimaryAmmoType != -1 ) ? pPlayer.m_rgAmmo( PrimaryAmmoType ) : 0;
                        PrimaryAmmoIndex = ( PrimaryAmmoIndex != -1 ) ? pPlayer.AmmoInventory( PrimaryAmmoIndex ) : 0;

                        SecondaryAmmoType = ( SecondaryAmmoType != -1 ) ? pPlayer.m_rgAmmo( SecondaryAmmoType ) : 0;
                        SecondaryAmmoIndex = ( SecondaryAmmoIndex != -1 ) ? pPlayer.AmmoInventory( SecondaryAmmoIndex ) : 0;

                        if( VerifyAmmo( pPlayer, PrimaryAmmoType, PrimaryAmmoIndex ) && VerifyAmmo( pPlayer, SecondaryAmmoType, SecondaryAmmoIndex ) )
                        {
                            CBaseEntity@ FakeWeapon = g_EntityFuncs.Create( WeaponName, pPlayer.pev.origin, pPlayer.pev.angles, false );
                            CBasePlayerWeapon@ FakeWeapon2 = cast<CBasePlayerWeapon@>( FakeWeapon );
                                    
                            FakeWeapon2.m_iDefaultAmmo = PrimaryAmmoValue;
                            FakeWeapon.pev.spawnflags = self.pev.spawnflags;
                        }
                    }
                    else
                    {
                        pPlayer.GiveAmmo( PrimaryAmmoValue, PrimaryAmmoName, pPlayer.GetMaxAmmo( PrimaryAmmoName ) );
                        pPlayer.GiveAmmo( SecondayAmmoValue, SecondaryAmmoName, pPlayer.GetMaxAmmo( SecondaryAmmoName ) );    
                    }
                }
                else
                {
                    pPlayer.GiveAmmo( PrimaryAmmoValue, PrimaryAmmoName, pPlayer.GetMaxAmmo( PrimaryAmmoName ) );
                    pPlayer.GiveAmmo( SecondayAmmoValue, SecondaryAmmoName, pPlayer.GetMaxAmmo( SecondaryAmmoName ) );
                }

                g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_ITEM, "items/gunpickup2.wav", 1, ATTN_NORM );
                g_EntityFuncs.Remove( self );
            }
        }
    }

    bool VerifyAmmo( CBasePlayer@ pPlayer, int AmmoType, int AmmoIndex )
    {
        return (AmmoType <= 0 && AmmoIndex <= 0 );
    }
}

void RegisterCustomWeaponBox()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "custom_weaponbox", "custom_weaponbox" );
    g_ItemRegistry.RegisterItem( "custom_weaponbox", "" );   
    g_Game.PrecacheOther( "custom_weaponbox" );
}