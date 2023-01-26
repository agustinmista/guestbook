{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

import Control.Monad.IO.Class
import GHC.Generics
import Data.IORef
import Data.Text
import Network.HTTP.Types
import Web.Scotty
import Network.Wai.Middleware.Static
import Network.Wai.Middleware.RequestLogger
import qualified Data.Aeson as Aeson

-- Guestbook goes brrr
main :: IO ()
main = do
  guestbook <- newGuestbook
  scotty 3000 (server guestbook)

----------------------------------------
-- The webserver

server :: Guestbook -> ScottyM ()
server guestbook = do
  -- Log requests to stdout
  middleware $ do
    logStdout

  -- Serve static files
  middleware $ do
    staticPolicy (noDots >-> addBase "static")

  -- Entry point
  get "/" $ do
    redirect "/index.html"

  -- Get messages
  get "/messages" $ do
    msgs <- liftIO (getMessages guestbook)
    json msgs

  -- New message
  post "/new" $ do
    msg <- jsonData
    liftIO (newMessage guestbook msg)
    status ok200

---------------------------------------
-- Guestbook data

data Message = Message {
  author :: Text,
  content :: Text
} deriving (Generic)

instance Aeson.ToJSON   Message
instance Aeson.FromJSON Message

newtype Guestbook = Guestbook (IORef [Message])

newGuestbook :: IO Guestbook
newGuestbook = Guestbook <$> newIORef []

getMessages :: Guestbook -> IO [Message]
getMessages (Guestbook ref) = readIORef ref

newMessage :: Guestbook -> Message -> IO ()
newMessage (Guestbook ref) msg = atomicModifyIORef' ref $ \msgs -> (msg:msgs, ())
