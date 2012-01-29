{-# LANGUAGE DeriveDataTypeable #-} 
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Hbro.Types where

-- {{{ Imports
import Control.Monad.Reader

import Data.Dynamic
import Data.IORef
import Data.Map
--import Data.Set

import Graphics.UI.Gtk.Builder
import Graphics.UI.Gtk.Display.Label
import Graphics.UI.Gtk.Entry.Entry
import Graphics.UI.Gtk.Layout.HBox
import Graphics.UI.Gtk.Gdk.EventM
import Graphics.UI.Gtk.Scrolling.ScrolledWindow
import Graphics.UI.Gtk.WebKit.WebPolicyDecision
import Graphics.UI.Gtk.WebKit.WebSettings
import Graphics.UI.Gtk.WebKit.WebView
import Graphics.UI.Gtk.Windows.Window

import Network.URI

import System.Console.CmdArgs
import System.Glib.Attributes
--import System.Glib.Signals
import System.ZMQ 
-- }}}

-- | Base type for high-level actions, mnemonics: K(it) from WebKit
type K = KT IO

newtype KT m a = KT (ReaderT Environment m a)
    deriving (Functor, Monad, MonadFix, MonadIO, MonadReader Environment, MonadTrans)

-- | The whole set of parameters, elements and states of the application
data Environment = Environment {
    mState   :: IORef (Map String Dynamic), -- ^ 
    mOptions :: CliOptions,               -- ^ Commandline options
    mConfig  :: Config,                   -- ^ Custom configuration provided by user
    mGUI     :: GUI,                      -- ^ Graphical widgets
    mContext :: Context                   -- ^ ZeroMQ context
}

-- | Set of commandline options
data CliOptions = CliOptions {
    mURI          :: Maybe String,     -- ^ URI to load at start-up
    mVanilla      :: Bool,             -- ^ Bypass custom configuration file
    mRecompile    :: Bool,             -- ^ Force recompilation and do not launch browser
    mDenyReconf   :: Bool,             -- ^ Do not recompile browser even if configuration file has changed
    mForceReconf  :: Bool,             -- ^ Force recompilation even if configuration file hasn't changed
    mDyreDebug    :: Bool,             -- ^ Look for a custom configuration file in current working directory
    mMasterBinary :: Maybe String      -- ^ Path to the master binary, used by Dyre 
} deriving (Data, Typeable, Show, Eq)

-- | Custom parameters provided by the user
data Config = {-forall a.-} Config {
    --mCommonDirectories :: CommonDirectories,               -- ^ Custom directories used to store various runtime and static files
    mSocketDir         :: RefDirs -> FilePath,             -- ^ Directory where 0MQ will be created ("/tmp" for example)
    mUIFile            :: RefDirs -> FilePath,             -- ^ Path to XML file describing UI (used by GtkBuilder)
    mHomePage          :: String,                          -- ^ Startup page 
    mWebSettings       :: [AttrOp WebSettings],            -- ^ WebSettings' attributes to use with webkit (see Webkit.WebSettings documentation)
--    mKeyEventHandler   :: KeyEventCallback -> ConnectId WebView -> WebView -> EventM EKey Bool,  -- ^ Key event handler, which forwards keystrokes to mKeyEventCallback
--    mKeyEventCallback  :: Environment -> KeyEventCallback, -- ^ Main key event callback, assumed to deal with each keystroke separately
    mCommands          :: CommandsList,                    -- ^ Custom commands to use with IPC sockets
    mHooks             :: Hooks,
    mError             :: Maybe String                     -- ^ Error
    --mCustom            :: a
}

-- | Set of functions to be triggered when some events occur
data Hooks = Hooks {
    mBackForward     :: URI -> WebPolicyDecision -> K (),             -- ^ Previous/next page has been requested
    mDownload        :: URI -> String -> Int -> K (),                 -- ^ A download has been requested
    mFormResubmitted :: URI -> WebPolicyDecision -> K(),              -- ^ A form has been resubmitted
    mFormSubmitted   :: URI -> WebPolicyDecision -> K (),             -- ^ A form has been submitted
    mKeyPressed      :: String -> K (),                               -- ^ 
    mLinkClicked     :: Button -> URI -> WebPolicyDecision -> K (),   -- ^ A link has been clicked
    mLoadFinished    :: K (),                                         -- ^ Load has finished
    mMIMEDisposition :: URI -> String -> WebPolicyDecision -> K (),
    mNewWindow       :: URI -> K (),                                  -- ^ A new window has been requested
    mOtherNavigation :: URI -> WebPolicyDecision -> K (),             -- ^ 
    mReload          :: URI -> WebPolicyDecision -> K (),             -- ^ A reload of the current page has been requested
    mStartUp         :: K (),                                         -- ^ At start-up
    mTitleChanged    :: String -> K ()                                -- ^ Title has changed
}

-- | Graphical elements
data GUI = GUI {
    mWindow             :: Window,          -- ^ Main window
    mInspectorWindow    :: Window,          -- ^ WebInspector window
    mScrollWindow       :: ScrolledWindow,  -- ^ ScrolledWindow containing the webview
    mWebView            :: WebView,         -- ^ Browser's webview
    mPromptBar          :: PromptBar,       -- ^ Prompt bar
    mStatusBar          :: HBox,            -- ^ Status bar's horizontal box
    mBuilder            :: Builder          -- ^ Builder object created from XML file
}

data PromptBar = PromptBar {
    mBox                    :: HBox,
    mDescription            :: Label,                  -- ^ Description of current prompt
    mEntry                  :: Entry,                  -- ^ Prompt entry
    mCallbackRef            :: IORef (String -> K ()), -- ^
    mIncrementalCallbackRef :: IORef (String -> K ())  -- ^
}

-- | Set of reference directories, typically used to build FilePath-s
data RefDirs = RefDirs {
    mHome          :: FilePath,        -- ^ Home directory
    mTemporary     :: FilePath,        -- ^ Temporary files directory
    mConfiguration :: FilePath,        -- ^ Configuration directory
    mData          :: FilePath         -- ^ Data directory
}

-- | List of bound keys.
-- All callbacks are fed with the Environment instance.
-- 
-- Note 1 : for modifiers, lists are used for convenience purposes,
--          but are transformed into sets in hbro's internal machinery,
--          so that order and repetition don't matter.
-- 
-- Note 2 : for printable characters accessed via the shift modifier,
--          you do have to include Shift in modifiers list.
type KeysList         = [(String, K ())]
type KeysMap          = Map String (K ())
type KeyEventCallback = [Modifier] -> String -> IO Bool
--data KeyMode          = CommandMode | InsertMode

type CommandsList = [(String, ([String] -> K String))]
type CommandsMap  = Map String ([String] -> K String)

-- |
data Button = ButtonL | ButtonM | ButtonR