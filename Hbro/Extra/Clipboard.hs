module Hbro.Extra.Clipboard where

-- {{{ Imports
import Hbro.Core
import Hbro.Types

import Graphics.UI.Gtk.Abstract.Widget
import Graphics.UI.Gtk.General.Clipboard
import Graphics.UI.Gtk.WebKit.WebView
-- }}}


-- | Copy current URI in clipboard.
copyUri :: Browser -> IO ()
copyUri browser = do
    getUri <- webViewGetUri (mWebView $ mGUI browser)
    primaryClip <- widgetGetClipboard (mWindow $ mGUI browser) selectionPrimary

    case getUri of
        Just u -> clipboardSetText primaryClip u
        _      -> return ()

-- | Copy current page title in clipboard.
copyTitle :: Browser -> IO ()
copyTitle browser = do
    getTitle    <- webViewGetTitle (mWebView $ mGUI browser)
    primaryClip <- widgetGetClipboard (mWindow $ mGUI browser) selectionPrimary

    case getTitle of
        Just t -> clipboardSetText primaryClip t
        _      -> return ()

-- | Load URI from clipboard. Does not work for now...
loadURIFromClipboard :: Browser -> IO ()
loadURIFromClipboard browser = do
    primaryClip <- widgetGetClipboard (mWindow $ mGUI browser) selectionPrimary

    _ <- clipboardRequestText primaryClip $ \x -> case x of
        Just uri -> putStrLn ("Loading URI from clipboard: " ++ uri) >> loadURL uri browser
        _        -> putStrLn "Loading URI from clipboard: empty clipboard."
    return ()