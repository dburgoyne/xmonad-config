
--------------------------------------------------------------------------------------------
-- ~/.xmonad/xmonad.hs                                                                    --
-- Authors: Nnoell <nnoell3[at]gmail.com>                                                 --
--          Dburgoyn <secure[at]dburgoyne.ca>                                             --
--------------------------------------------------------------------------------------------


-- Language
{-# LANGUAGE DeriveDataTypeable, NoMonomorphismRestriction, TypeSynonymInstances, MultiParamTypeClasses,  ImplicitParams, PatternGuards #-}

-- GHC options
{-# OPTIONS_GHC -W -fwarn-unused-imports -fno-warn-missing-signatures -fcontext-stack=50 #-}

-- Imported libraries
import Control.Concurrent
import XMonad
import XMonad.Core
import XMonad.Layout
import XMonad.Layout.IM
import XMonad.Layout.Gaps
import XMonad.Layout.Named
import XMonad.Layout.Tabbed
import XMonad.Layout.OneBig
import XMonad.Layout.Master
import XMonad.Layout.Reflect
import XMonad.Layout.MosaicAlt
import XMonad.Layout.NoFrillsDecoration
import XMonad.Layout.SimplestFloat
import XMonad.Layout.NoBorders (noBorders,smartBorders,withBorder)
import XMonad.Layout.ResizableTile
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances
import XMonad.Layout.PerWorkspace (onWorkspace)
import XMonad.Layout.Minimize
import XMonad.Layout.Maximize
import XMonad.Layout.WindowNavigation
import XMonad.StackSet (RationalRect (..), currentTag)
import XMonad.Util.Loggers
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.DynamicHooks
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.UrgencyHook
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.SetWMName
import XMonad.Hooks.ManageHelpers
import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Prompt.XMonad
import XMonad.Prompt.Man
import XMonad.Util.Timer
import XMonad.Util.Cursor
import XMonad.Util.EZConfig
import XMonad.Util.Run
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.NamedScratchpad
import XMonad.Actions.CycleWS
import XMonad.Actions.GridSelect
import XMonad.Actions.MouseResize
import XMonad.Actions.PhysicalScreens  -- For switching screens in physical order, as defined by Xinerama
import Data.IORef
import Data.Monoid
import Data.List
import Graphics.X11.ExtraTypes.XF86
import System.Exit
import System.IO (Handle, hPutStrLn)
import System.IO
import qualified XMonad.StackSet as W
import qualified Data.Map as M
import qualified XMonad.Actions.FlexibleResize as Flex
import qualified XMonad.Util.ExtensibleState as XS

-- Main
main :: IO ()

main = do
	topLeftBar              <- spawnPipe myTopLeftBar
	topRightBar             <- spawnPipe myTopRightBar
	workspaceBar            <- spawnPipe myWorkspaceBar
	bottomBar               <- spawnPipe myBottomRightBar
	systemTray              <- spawnPipe mySystemTray
	focusFollow             <- newIORef True; let ?focusFollow = focusFollow
	xmonad $ myUrgencyHook $ defaultConfig
		{ terminal           = myTerminal
		, modMask            = mod4Mask
		, focusFollowsMouse  = False
		, borderWidth        = 1
		, normalBorderColor  = myNormalBorderColor
		, focusedBorderColor = myFocusedBorderColor
		, layoutHook         = myLayoutHook
		, workspaces         = myWorkspaces
		, manageHook         = myManageHook <+> namedScratchpadManageHook scratchpads <+> manageDocks <+> dynamicMasterHook
		, logHook            = myLogHook workspaceBar <+> myLogHook2 topLeftBar <+> myLogHook3 topRightBar <+> ewmhDesktopsLogHook >> setWMName "LG3D"
		, handleEventHook    = myHandleEventHook
		, keys               = myKeys
		, mouseBindings      = myMouseBindings
		, startupHook        = (startTimer 1 >>= XS.put . TID) <+> setDefaultCursor xC_left_ptr >> setWMName "LG3D"
		}
		`additionalKeysP`
		[ ("M-v", io $ modifyIORef ?focusFollow not)                         --Toggle focus follow moouse
		]

--------------------------------------------------------------------------------------------
-- APPEARANCE CONFIG                                                                      --
--------------------------------------------------------------------------------------------

-- Colors, fonts and paths
dzenFont             = "-*-terminus-*-r-normal-*-14-*-*-*-*-*-*-*" -- "-*-dejavu sans-medium-r-normal-*-11-*-*-*-*-*-*-*" 
colorBlack           = "#303030" --Background (Dzen_BG)
colorBlackAlt        = "#000000" --Black Xdefaults    ccQqqq
colorGray            = "#151515" --Gray       (Dzen_FG2)
colorGrayAlt         = "#151515" --Gray dark
colorWhite           = "#f5f5f5" --Foreground (Shell_FG)
colorWhiteAlt        = "#f5f5f5" --White dark (Dzen_FG)
colorMagenta         = "#fb9fb1"
colorBlue            = "#6fc2ef"
colorBlueAlt         = "#3955c4"
colorRed             = "#fb9fb1"
colorGreen           = "#acc267"
colorGreenAlt        = "#acc267"
myNormalBorderColor  = colorBlack
myFocusedBorderColor = colorBlue
myIconPath           = "/home/dburgoyne/Scripts/xmonad/"
myBinPath            = "/home/dburgoyne/Scripts/xmonad/"
-- Dimensions of the primary display, where the dzen2 bars will go.
xRes                 = 2560
yRes                 = 1600
-- Distance from the top-left corner of the X display to the top-left corner of the primary display, in pixels.
xOffset              = 1200
yOffset              = 0
-- How much more space to give the bottom-right statusbar over the bottom-left one.  If 0, they will have the same size.
-- The bottom-right bar is typically bigger and so a positive value is useful here.
xShift	             = 440
-- Vertical height of the dzen2 bars.
panelHeight          = 18
-- Vertical height of the text boxes inside the dzen2 bars.
panelBoxHeight       = 14
-- System tray dimensions.
maxIcons             = 4
trayRes              = panelHeight * maxIcons

-- Terminal
myTerminal = "/usr/bin/urxvtc"

-- Editor
myEditor = myTerminal ++ " -e emacsclient -t -a ''"

-- Title theme
myTitleTheme :: Theme
myTitleTheme = defaultTheme
	{ fontName            = dzenFont
	, inactiveBorderColor = colorBlackAlt
	, inactiveColor       = colorBlack
	, inactiveTextColor   = colorGray
	, activeBorderColor   = colorGray
	, activeColor         = colorBlackAlt
	, activeTextColor     = colorWhiteAlt
	, urgentBorderColor   = colorGray
	, urgentTextColor     = colorGreen
	, decoHeight          = 14
	}

-- Prompt theme
myXPConfig :: XPConfig
myXPConfig = defaultXPConfig
	{ font                = dzenFont
	, bgColor             = colorBlack
	, fgColor             = colorWhite
	, bgHLight            = colorBlue
	, fgHLight            = colorBlack
	, borderColor         = colorGrayAlt
	, promptBorderWidth   = 1
	, height              = panelHeight
	, position            = Top
	, historySize         = 100
	, historyFilter       = deleteConsecutive
	, autoComplete        = Nothing
	}

-- GridSelect color scheme
myColorizer :: Window -> Bool -> X (String, String)
myColorizer = colorRangeFromClassName
	(0x00,0x00,0x00) -- lowest inactive bg
	(0x1C,0x1C,0x1C) -- highest inactive bg
	(0x44,0xAA,0xCC) -- active bg
	(0xBB,0xBB,0xBB) -- inactive fg
	(0x00,0x00,0x00) -- active fg

-- GridSelect theme
myGSConfig :: t -> GSConfig Window
myGSConfig colorizer = (buildDefaultGSConfig myColorizer)
	{ gs_cellheight  = 54
	, gs_cellwidth   = 192
	, gs_cellpadding = 10
	, gs_font        = dzenFont
	}

-- Workspaces
myWorkspaces :: [WorkspaceId]
myWorkspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

--------------------------------------------------------------------------------------------
-- LAYOUT CONFIG                                                                          --
--------------------------------------------------------------------------------------------

-- Layouts (name must be diferent of Minimize, Maximize and Mirror)
myTile = named "ResizableTall"     $ smartBorders $ ResizableTall 1 0.03 0.5 []
myMirr = named "MirrResizableTall" $ smartBorders $ Mirror myTile
myMosA = named "MosaicAlt"         $ smartBorders $ MosaicAlt M.empty
myObig = named "OneBig"            $ smartBorders $ OneBig 0.75 0.65
myTabs = named "Simple Tabbed"     $ smartBorders $ tabbed shrinkText myTitleTheme
myFull = named "Full Tabbed"       $ smartBorders $ tabbedAlways shrinkText myTitleTheme
myTabM = named "Master Tabbed"     $ smartBorders $ mastered 0.01 0.4 $ tabbed shrinkText myTitleTheme
myFlat = named "Simple Float"      $ mouseResize  $ noFrillsDeco shrinkText myTitleTheme simplestFloat

-- Tabbed transformer (W+f)
data TABBED = TABBED deriving (Read, Show, Eq, Typeable)
instance Transformer TABBED Window where
	transform TABBED x k = k myFull (\_ -> x)

-- Floated transformer (W+ctl+f)
data FLOATED = FLOATED deriving (Read, Show, Eq, Typeable)
instance Transformer FLOATED Window where
	transform FLOATED x k = k myFlat (\_ -> x)

-- Layout hook
myLayoutHook = gaps [(U,panelHeight), (D,panelHeight), (L,0), (R,0)]
	$ avoidStruts
	$ windowNavigation
	$ minimize
	$ maximize
	$ mkToggle (single TABBED)
	$ mkToggle (single FLOATED)
	$ mkToggle (single MIRROR)
	$ mkToggle (single REFLECTX)
	$ mkToggle (single REFLECTY)
	-- $ onWorkspace (myWorkspaces !! 1) webLayouts  --Workspace 2 layouts
	-- $ onWorkspace (myWorkspaces !! 2) codeLayouts --Workspace 3 layouts
	$ allLayouts
	where
		allLayouts  = myTile ||| myObig ||| myMirr ||| myMosA ||| myTabs ||| myTabM
		webLayouts  = myTabs ||| myMirr ||| myTabM
		codeLayouts = myTabM ||| myTile
		
--------------------------------------------------------------------------------------------
-- HANDLE EVENT HOOK CONFIG                                                               --
--------------------------------------------------------------------------------------------

-- wrapper for the Timer id, so it can be stored as custom mutable state
data TidState = TID TimerId deriving Typeable

instance ExtensionClass TidState where
  initialValue = TID 0

-- Handle event hook
myHandleEventHook :: (?focusFollow::IORef Bool) => Event -> X All
myHandleEventHook = fullscreenEventHook <+> docksEventHook <+> toggleFocus <+> clockEventHook
	where
		toggleFocus e = case e of --thanks to Vgot
			CrossingEvent {ev_window=w, ev_event_type=t}
				| t == enterNotify, ev_mode e == notifyNormal -> do
					whenX (io $ readIORef ?focusFollow) (focus w)
					return $ All True
			_ -> return $ All True
		clockEventHook e = do                   --thanks to DarthFennec
			(TID t) <- XS.get                   --get the recent Timer id
			handleTimer t e $ do                --run the following if e matches the id
			    startTimer 1 >>= XS.put . TID   --restart the timer, store the new id
			    ask >>= logHook.config          --get the loghook and run it
			    return Nothing                  --return required type
			return $ All True                   --return required type

--------------------------------------------------------------------------------------------
-- MANAGE HOOK CONFIG                                                                     --
--------------------------------------------------------------------------------------------

-- Scratchpads (F11, F12)
-- W.RationalRect l t w h
scratchpads = 
	[ NS "scratchpad_top" (myTerminal ++ " -name scratchpad_top") (resource =? "scratchpad_top") (customFloating $ W.RationalRect l t2 w h)
	, NS "scratchpad_bottom" (myTerminal ++ " -name scratchpad_bottom") (resource =? "scratchpad_bottom") (customFloating $ W.RationalRect l t1 w h)
	]
	where
		h  = 0.25                            -- terminal height
		w  = 1                               -- terminal width
		t1 = (1 - h) - (panelHeight / yRes)  -- distance from top edge
		t2 = panelHeight / yRes
		l  = (1 - w) / 2                     -- distance from left edge

-- Manage hook
myManageHook :: ManageHook
myManageHook = composeAll . concat $
	[ [resource     =? r     --> doIgnore                             | r <- myIgnores] --ignore desktop
	, [className    =? c     --> doShift (myWorkspaces !! 1)          | c <- myWebS   ] --move myWebS windows to workspace 2 by classname
	, [className    =? c     --> doShift (myWorkspaces !! 2)          | c <- myCodeS  ] --move myCodeS windows to workspace 3 by classname
	, [className    =? c     --> doShift (myWorkspaces !! 3)          | c <- myChatS  ] --move myChatS windows to workspace 4 by classname
	, [className    =? c     --> doShiftAndGo (myWorkspaces !! 5)     | c <- myAlt1S  ] --move myGameS windows to workspace 5 by classname and shift
	, [className    =? c     --> doShift (myWorkspaces !! 6)          | c <- myAlt3S  ] --move myOtherS windows to workspace 5 by classname
	, [className    =? c     --> doCenterFloat                        | c <- myFloatCC] --float center geometry by classname
	, [name         =? n     --> doCenterFloat                        | n <- myFloatCN] --float center geometry by name
	, [name         =? n     --> doSideFloat NW                       | n <- myFloatSN] --float side NW geometry by name
	, [className    =? c     --> doF W.focusDown                      | c <- myFocusDC] --dont focus on launching by classname
	, [isFullscreen          --> doFullFloat]
	, [ title       =? t     --> doFloat                              | t <- myOtherFloats]
	]
	where
		doShiftAndGo ws = doF (W.greedyView ws) <+> doShift ws
		role            = stringProperty "WM_WINDOW_ROLE"
		name            = stringProperty "WM_NAME"
		myIgnores       = ["desktop","desktop_window"]
		myWebS          = ["Chromium","Firefox"]
		myCodeS         = ["NetBeans IDE 7.2"]
		myChatS         = ["Pidgin", "Xchat"]
		myAlt1S         = ["zsnes"]
		myAlt3S         = ["KTorrent"]
		myFloatCC       = ["Gksu", "XFontSel", "XCalc", "XClock"]
		myFloatCN       = [ "Select one or more files to open", "Add media", "Choose a file", "Open Image", "File Operation Progress", "Firefox Preferences", "Preferences", "Search Engines"
						  , "Set up sync", "Passwords and Exceptions", "Autofill Options", "Rename File", "Copying files", "Moving files", "File Properties", "Replace", "Welcome to Wolfram Mathematica", "Wolfram Mathematica 10.0", ""]
		myFloatSN       = ["Event Tester"]
		myFocusDC       = ["Event Tester", "Notify-osd"]
		myOtherFloats   = []


--------------------------------------------------------------------------------------------
-- STATUS BARS CONFIG                                                                     --
--------------------------------------------------------------------------------------------

-- UrgencyHook
myUrgencyHook = withUrgencyHook dzenUrgencyHook
	{ args = ["-fn", dzenFont, "-bg", colorBlack, "-fg", colorGreen, "-h", show panelHeight] }

-- System tray
mySystemTray =  "/usr/bin/stalonetray"
	++ " -i " ++ show panelHeight
	++ " --max-geometry " ++ show maxIcons ++ "x1"
	++ " --geometry " ++ show maxIcons ++ "x1+" ++ show (xOffset+xRes-trayRes) ++ "+" ++ show yOffset
	++ " -bg '" ++ colorBlack ++ "'"
	++ " --icon-gravity E"
	++ " --sticky"
	++ " --skip-taskbar"

-- Bottom right bar
myBottomRightBar = myBinPath ++ "bottomBar.sh"
	++ " -xres " ++ show xRes
	++ " -yres " ++ show yRes
        ++ " -xoffset " ++ show xOffset
	++ " -yoffset " ++ show yOffset
	++ " -boxheight " ++ show panelBoxHeight
	++ " -height " ++ show panelHeight
	++ " -width " ++ show (xRes/2 + xShift)

-- WorkspaceBar
myWorkspaceBar = "dzen2 -x " ++ show xOffset ++ " -y " ++ show (yRes + yOffset) ++ " -h " ++ show panelHeight ++ " -w " ++ show (xRes/2 - xShift) ++ " -ta 'l' -fg '" ++ colorWhiteAlt ++ "' -bg '" ++ colorBlack ++ "' -fn '" ++ dzenFont ++ "' -p -e 'onstart=lower'"
myLogHook :: Handle -> X ()
myLogHook h = dynamicLogWithPP $ defaultPP
	{ ppOutput          = hPutStrLn h
	, ppSort            = fmap (namedScratchpadFilterOutWorkspace .) (ppSort defaultPP) --hide "NSP" from workspace list
	, ppOrder           = \(ws:l:_:x) -> [ws,l]
	, ppSep             = " "
	, ppWsSep           = ""
	, ppCurrent         = wrapTextBox colorBlack    colorBlue    colorBlack
	, ppUrgent          = wrapTextBox colorBlack    colorGreen   colorBlack . wrapClickWorkspace
	, ppVisible         = wrapTextBox colorBlack    colorGrayAlt colorBlack . wrapClickWorkspace
	, ppHiddenNoWindows = wrapTextBox colorBlack    colorGrayAlt colorBlack . wrapClickWorkspace
	, ppHidden          = wrapTextBox colorWhiteAlt colorGrayAlt colorBlack . wrapClickWorkspace
	, ppLayout          = \l -> (wrapClickLayout (wrapTextBox colorBlue colorGrayAlt colorBlack "LAYOUT")) ++ (wrapTextBox colorGray colorGrayAlt colorBlack $ layoutText $ removeWord $ removeWord l)
	}
	where
		removeWord = tail . dropWhile (/= ' ')
		layoutText xs
			| isPrefixOf "Mirror" xs   = layoutText $ removeWord xs ++ " [M]"
			| isPrefixOf "ReflectY" xs = layoutText $ removeWord xs ++ " [Y]"
			| isPrefixOf "ReflectX" xs = layoutText $ removeWord xs ++ " [X]"
			| isPrefixOf "Float" xs    = "^fg(" ++ colorRed ++ ")" ++ xs
			| isPrefixOf "Full" xs     = "^fg(" ++ colorGreen ++ ")" ++ xs
			| otherwise                = "^fg(" ++ colorWhiteAlt ++ ")" ++ xs

-- TopLeftBar
myTopLeftBar = "dzen2 -x " ++ show xOffset ++ " -y " ++ show yOffset ++ " -h " ++ show panelHeight ++ " -w " ++ show (xRes/2) ++ " -ta 'l' -fg '" ++ colorWhiteAlt ++ "' -bg '" ++ colorBlack ++ "' -fn '" ++ dzenFont ++ "' -p -e 'onstart=lower'"

myLogHook2 :: Handle -> X ()
myLogHook2 h = dynamicLogWithPP $ defaultPP
	{ ppOutput          = hPutStrLn h
	, ppOrder           = \(_:_:_:x) -> x
	, ppSep             = " "
	, ppExtras          = [ wrapL (wrapClickGrid $ wrapTextBox colorBlue  colorGrayAlt  colorBlack "WORKSPACE") "" $ wrapLoggerBox colorWhiteAlt colorGrayAlt colorBlack $ onLogger namedWorkspaces logCurrent
						  , wrapL (wrapClickTitle $ wrapTextBox colorBlue colorGrayAlt colorBlack "FOCUS") "" $ wrapLoggerBox colorWhiteAlt colorGrayAlt colorBlack $ shortenL 144 logTitle
						  ]
	}
	where
		namedWorkspaces w
			| w == "1"  = "^fg(" ++ colorGreen ++ ")1^fg(" ++ colorGray ++ ")|^fg()Terminal"
			| w == "2"  = "^fg(" ++ colorGreen ++ ")2^fg(" ++ colorGray ++ ")|^fg()Browsing"
			| w == "3"  = "^fg(" ++ colorGreen ++ ")3^fg(" ++ colorGray ++ ")|^fg()Development"
			| w == "4"  = "^fg(" ++ colorGreen ++ ")4^fg(" ++ colorGray ++ ")|^fg()Chatting"
			| w == "5"  = "^fg(" ++ colorGreen ++ ")5^fg(" ++ colorGray ++ ")|^fg()Network"
			| w == "6"  = "^fg(" ++ colorGreen ++ ")6^fg(" ++ colorGray ++ ")|^fg()Alternative"
			| w == "7"  = "^fg(" ++ colorGreen ++ ")7^fg(" ++ colorGray ++ ")|^fg()Alternative"
			| w == "8"  = "^fg(" ++ colorGreen ++ ")8^fg(" ++ colorGray ++ ")|^fg()Alternative"
			| w == "9"  = "^fg(" ++ colorGreen ++ ")9^fg(" ++ colorGray ++ ")|^fg()Alternative"
			| otherwise = "^fg(" ++ colorRed   ++ ")x^fg(" ++ colorGray ++ ")|^fg()" ++ w

-- TopRightBar
myTopRightBar = "dzen2 -x " ++ show (xOffset+xRes/2) ++ " -y " ++ show yOffset ++ " -h " ++ show panelHeight ++ " -w " ++ show (xRes/2 - trayRes) ++ " -ta 'r' -fg '" ++ colorWhiteAlt ++ "' -bg '" ++ colorBlack ++ "' -fn '" ++ dzenFont ++ "' -p -e 'onstart=lower'"
myLogHook3 :: Handle -> X ()
myLogHook3 h = dynamicLogWithPP $ defaultPP
	{ ppOutput          = hPutStrLn h
    , ppOrder           = \(_:_:_:x) -> x
	, ppSep             = " "
	, ppExtras          = [-- return $ return $ wrapTextBox colorWhiteAlt colorGrayAlt colorBlack "DB"
						  --, wrapLoggerBox colorBlue colorGrayAlt colorBlack (logCmd $ myBinPath ++ "/drop_check.sh")
						  --, return $ return $ wrapTextBox colorWhiteAlt colorGrayAlt colorBlack "PM"
						  --, wrapLoggerBox colorBlue colorGrayAlt colorBlack (logCmd $ myBinPath ++ "/pac_check.sh")
						  wrapLoggerBox colorBlack colorWhiteAlt colorBlack (logCmd "date +%A")
						  , date $ (wrapTextBox colorWhiteAlt colorGrayAlt colorBlack $ "%Y^fg(" ++ colorGray ++ ").^fg()%m^fg(" ++ colorGray ++ ").^fg()^fg(" ++ colorBlue ++ ")%d^fg() ^fg(" ++ colorGray ++ ")-^fg() %H^fg(" ++ colorGray ++"):^fg()%M^fg(" ++ colorGray ++ "):^fg()^fg(" ++ colorGreen ++ ")%S^fg()")
                          , return $ return $ wrapClickCalendar $ wrapTextBox colorBlue colorGrayAlt colorBlack "CALENDAR"
						  ]
	}
-- (runProcessWithInput "date"  [] "+%A")
-- Wrap Clickable Area
wrapClickGrid x = "^ca(1,/usr/bin/xdotool key super+g)" ++ x ++ "^ca()"
wrapClickCalendar x = "^ca(1," ++ myBinPath ++ "dzencal.sh)" ++ x ++ "^ca()"
wrapClickLayout x = "^ca(1,/usr/bin/xdotool key super+space)^ca(3,/usr/bin/xdotool key super+shift+space)" ++ x ++ "^ca()^ca()"
wrapClickTitle x = "^ca(1,/usr/bin/xdotool key super+m)^ca(2,/usr/bin/xdotool key super+c)^ca(3,/usr/bin/xdotool key super+shift+m)" ++ x ++ "^ca()^ca()^ca()"
-- Left / middle / right clicking on a workspace displays it on the left / middle / right monitor, respectively.
wrapClickWorkspace ws = "^ca(1," ++ xdo "w;" ++ xdo index ++ ")" ++ "^ca(2," ++ xdo "e;" ++ xdo index ++ ")" ++ "^ca(3," ++ xdo "r;" ++ xdo index ++ ")" ++ ws ++ "^ca()^ca()^ca()"
	where
		wsIdxToString Nothing = "1"
		wsIdxToString (Just n) = show $ (+ 1) $ mod n $ length myWorkspaces
		index = wsIdxToString (elemIndex ws myWorkspaces)
		xdo key = "/usr/bin/xdotool key super+" ++ key

-- Wrap Box
wrapTextBox :: String -> String -> String -> String -> String
wrapTextBox fg bg1 bg2 t = "^fg(" ++ bg1 ++ ")^i(" ++ myIconPath  ++ "boxleft16.xbm)^ib(1)^r(" ++ show xRes ++ "x" ++ show panelBoxHeight ++ ")^p(-" ++ show xRes ++ ")^fg(" ++ fg ++ ")" ++ t ++ "^fg(" ++ bg1 ++ ")^i(" ++ myIconPath ++ "boxright16.xbm)^fg(" ++ bg2 ++ ")^r(" ++ show xRes ++ "x" ++ show panelBoxHeight ++ ")^p(-" ++ show xRes ++ ")^fg()^ib(0)"

wrapLoggerBox :: String -> String -> String -> Logger -> Logger
wrapLoggerBox fg bg1 bg2 l = do
	log <- l
	let text = do
		logStr <- log
		return $ wrapTextBox fg bg1 bg2 logStr
	return text


--------------------------------------------------------------------------------------------
-- BINDINGS CONFIG                                                                        --
--------------------------------------------------------------------------------------------

-- Key bindings
myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
	-- Xmonad bindings
	[((modMask .|. shiftMask, xK_q), killAndExit)                                               --Quit xmonad
	, ((modMask, xK_q), killAndRestart)                                                         --Restart xmonad
	, ((mod1Mask, xK_F2), shellPrompt myXPConfig)                                               --Launch Xmonad shell prompt
	, ((modMask, xK_F2), xmonadPrompt myXPConfig)                                               --Launch Xmonad prompt
	, ((mod1Mask, xK_F3), manPrompt myXPConfig)                                                 --Launch man prompt
	, ((modMask, xK_g), goToSelected $ myGSConfig myColorizer)                                  --Launch GridSelect
	, ((0, xK_F12), namedScratchpadAction scratchpads "scratchpad_top")                         --Toggle top scratchpad
	, ((0, xK_F11), namedScratchpadAction scratchpads "scratchpad_bottom")                      --Toggle bottom scratchpad
	, ((modMask .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf)                        --Launch default terminal
	, ((modMask, xK_Return), spawn myEditor)                                                    --Launch emacs
	, ((controlMask, xK_Escape), spawn $ XMonad.terminal conf ++ " -e htop")                    --Launch system monitor
	-- Window management bindings
	, ((modMask, xK_c), kill)                                                                   --Close focused window
	, ((mod1Mask, xK_F4), kill)
	, ((modMask, xK_n), refresh)                                                                --Resize viewed windows to the correct size
	, ((modMask, xK_Tab), windows W.focusDown)                                                  --Move focus to the next window
	, ((modMask, xK_j), windows W.focusDown)
	, ((mod1Mask, xK_Tab), windows W.focusDown)
	, ((modMask, xK_k), windows W.focusUp)                                                      --Move focus to the previous window
	, ((modMask, xK_a), windows W.focusMaster)                                                  --Move focus to the master window
	, ((modMask .|. shiftMask, xK_a), windows W.swapMaster)                                     --Swap the focused window and the master window
	, ((modMask .|. shiftMask, xK_j), windows W.swapDown)                                       --Swap the focused window with the next window
	, ((modMask .|. shiftMask, xK_k), windows W.swapUp)                                         --Swap the focused window with the previous window
	, ((modMask, xK_h), sendMessage Shrink)                                                     --Shrink the master area
	, ((modMask .|. shiftMask, xK_Left), sendMessage Shrink)
	, ((modMask, xK_l), sendMessage Expand)                                                     --Expand the master area
	, ((modMask .|. shiftMask, xK_Right), sendMessage Expand)
	, ((modMask .|. shiftMask, xK_h), sendMessage MirrorShrink)                                 --MirrorShrink the master area
	, ((modMask .|. shiftMask, xK_Down), sendMessage MirrorShrink)
	, ((modMask .|. shiftMask, xK_l), sendMessage MirrorExpand)                                 --MirrorExpand the master area
	, ((modMask .|. shiftMask, xK_Up), sendMessage MirrorExpand)
	, ((modMask, xK_t), withFocused $ windows . W.sink)                                         --Push window back into tiling
	, ((modMask .|. shiftMask, xK_t), rectFloatFocused)                                         --Push window into float
	, ((modMask, xK_m), withFocused minimizeWindow)                                             --Minimize window
	, ((modMask, xK_b), withFocused (sendMessage . maximizeRestore))                            --Maximize window
	, ((modMask .|. shiftMask, xK_m), sendMessage RestoreNextMinimizedWin)                      --Restore window
	, ((modMask .|. shiftMask, xK_f), fullFloatFocused)                                         --Push window into full screen
	, ((modMask, xK_comma), sendMessage (IncMasterN 1))                                         --Increment the number of windows in the master area
	, ((modMask, xK_period), sendMessage (IncMasterN (-1)))                                     --Deincrement the number of windows in the master area
	, ((modMask, xK_Right), sendMessage $ Go R)                                                 --Change focus to right
	, ((modMask, xK_Left ), sendMessage $ Go L)                                                 --Change focus to left
	, ((modMask, xK_Up   ), sendMessage $ Go U)                                                 --Change focus to up
	, ((modMask, xK_Down ), sendMessage $ Go D)                                                 --Change focus to down
	, ((modMask .|. controlMask, xK_Right), sendMessage $ Swap R)                               --Swap focused window to right
	, ((modMask .|. controlMask, xK_Left ), sendMessage $ Swap L)                               --Swap focused window to left
	, ((modMask .|. controlMask, xK_Up   ), sendMessage $ Swap U)                               --Swap focused window to up
	, ((modMask .|. controlMask, xK_Down ), sendMessage $ Swap D)                               --Swap focused window to down
	-- Layout management bindings
	, ((modMask, xK_space), sendMessage NextLayout)                                             --Rotate through the available layout algorithms
	, ((modMask .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf)                  --Reset the layout on the current workspace to default
	, ((modMask, xK_f), sendMessage $ XMonad.Layout.MultiToggle.Toggle TABBED)                  --Push layout into tabbed
	, ((modMask .|. controlMask, xK_f), sendMessage $ XMonad.Layout.MultiToggle.Toggle FLOATED) --Push layout into float
	, ((modMask .|. shiftMask, xK_z), sendMessage $ Toggle MIRROR)                              --Push layout into mirror
	, ((modMask .|. shiftMask, xK_x), sendMessage $ XMonad.Layout.MultiToggle.Toggle REFLECTX)  --Reflect layout by X
	, ((modMask .|. shiftMask, xK_y), sendMessage $ XMonad.Layout.MultiToggle.Toggle REFLECTY)  --Reflect layout by Y
	-- Gaps management bindings
	, ((modMask .|. controlMask, xK_t), sendMessage $ ToggleGaps)                               --toogle all gaps
	, ((modMask .|. controlMask, xK_u), sendMessage $ ToggleGap U)                              --toogle the top gap
	, ((modMask .|. controlMask, xK_d), sendMessage $ ToggleGap D)                              --toogle the bottom gap
	-- Scripts management bindings
	, ((mod1Mask, xK_Caps_Lock), spawn $ myBinPath ++ "switch-keyboard-layout.sh")              --Switch the keyboard layout
	, ((mod1Mask .|. controlMask .|. shiftMask, xK_l), spawn "slimlock") 
	, ((0, xF86XK_AudioMute), spawn "/usr/bin/mute_toggle")                                     --Mute/unmute volume
	, ((0, xF86XK_AudioRaiseVolume), spawn "/usr/bin/vol_up")                                   --Raise volume
	-- , ((mod1Mask, xK_Up), spawn "/usr/bin/vol_up")
	, ((0, xF86XK_AudioLowerVolume), spawn "/usr/bin/vol_down")                                 --Lower volume
	-- , ((mod1Mask, xK_Down), spawn "/usr/bin/vol_down")
	, ((0, xF86XK_AudioNext), spawn "/usr/bin/ncmpcpp next")                                    --Next song
	-- , ((mod1Mask, xK_Right), spawn "/usr/bin/ncmpcpp next")
	, ((0, xF86XK_AudioPrev), spawn "/usr/bin/ncmpcpp prev")                                    --Prev song
	-- , ((mod1Mask, xK_Left), spawn "/usr/bin/ncmpcpp prev")
	, ((0, xF86XK_AudioPlay), spawn "/usr/bin/ncmpcpp toggle")                                  --Toggle song
	-- , ((mod1Mask .|. controlMask, xK_Down), spawn "/usr/bin/ncmpcpp toggle")
	, ((0, xF86XK_AudioStop), spawn "/usr/bin/ncmpcpp stop")                                    --Stop song
	-- , ((mod1Mask .|. controlMask, xK_Up), spawn "ncmpcpp stop")
	, ((0, xF86XK_KbdBrightnessUp), spawn "~/Scripts/g73/light_up.sh")                          --Keyboard backlight up
	, ((0, xF86XK_KbdBrightnessDown), spawn "~/Scripts/g73/light_down.sh")                      --Keyboard backlight down
	, ((0, xF86XK_MonBrightnessUp), spawn "/usr/bin/xbacklight -inc 20")                          --Screen backlight up
	, ((0, xF86XK_MonBrightnessDown), spawn "/usr/bin/xbacklight -dec 20")   					--Screen backlight down
	, ((0, xK_Print), spawn "/usr/bin/scrot '%Y-%m-%d_$wx$h.png'")                              --Take a screenshot
	-- , ((modMask , xK_s), spawn $ myBinPath ++ "turnoffscreen.sh")                               --Turn off screen
	--Workspaces management bindings
	, ((mod1Mask, xK_comma), toggleWS)                                                          --Toggle to the workspace displayed previously
	, ((mod1Mask, xK_masculine), toggleOrView (myWorkspaces !! 0))                              --If ws != 0 then move to workspace 0, else move to latest ws I was
	, ((mod1Mask .|. controlMask, xK_Left),  moveTo Prev (WSIs notSP))                                            --Move to previous Workspace
	, ((mod1Mask .|. controlMask, xK_Right), moveTo Next (WSIs notSP))                                            --Move to next Workspace
	, ((mod1Mask .|. controlMask .|. shiftMask, xK_Left),  shiftTo Prev (WSIs notSP) >> moveTo Prev (WSIs notSP))                          --Send client to next workspace
	, ((mod1Mask .|. controlMask .|. shiftMask, xK_Right), shiftTo Next (WSIs notSP) >> moveTo Next (WSIs notSP))                         --Send client to previous workspace
	]
	++
	[((m .|. modMask, k), windows $ f i)                                                        --Switch to n workspaces and send client to n workspaces
		| (i, k) <- zip (XMonad.workspaces conf) ([xK_1 .. xK_9] ++ [xK_0])
		, (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
	++
        [((m .|. modMask, key), f sc)                                                               --Switch to n screens and send client to n screens
            | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
            , (f, m) <- [(viewScreen, 0), (sendToScreen, shiftMask)]]
	where
		fullFloatFocused = withFocused $ \f -> windows =<< appEndo `fmap` runQuery doFullFloat f
		rectFloatFocused = withFocused $ \f -> windows =<< appEndo `fmap` runQuery (doRectFloat $ RationalRect 0.05 0.05 0.9 0.9) f
		notSP = (return $ ("NSP" /=) . W.tag) :: X (WindowSpace -> Bool)
		killAndExit =
			io (exitWith ExitSuccess)
		killAndRestart =
		    (spawn "/usr/bin/killall dzen2 stalonetray") <+>
			(liftIO $ threadDelay 1000000) <+>
			(restart "xmonad" True)

-- Mouse bindings
myMouseBindings :: XConfig Layout -> M.Map (KeyMask, Button) (Window -> X ())
myMouseBindings (XConfig {XMonad.modMask = modMask}) = M.fromList $
	[ ((modMask, button1), (\w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster)) --Set the window to floating mode and move by dragging
	, ((modMask, button2), (\w -> focus w >> windows W.shiftMaster))                      --Raise the window to the top of the stack
	, ((modMask, button3), (\w -> focus w >> Flex.mouseResizeWindow w))                   --Set the window to floating mode and resize by dragging
	, ((modMask, button4), (\_ -> prevWS))                                                --Switch to previous workspace
	, ((modMask, button5), (\_ -> nextWS))                                                --Switch to next workspace
	, (((modMask .|. shiftMask), button4), (\_ -> shiftToPrev))                           --Send client to previous workspace
	, (((modMask .|. shiftMask), button5), (\_ -> shiftToNext))                           --Send client to next workspace
	]
