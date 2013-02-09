{-# LANGUAGE OverloadedStrings #-}

import           Control.Monad
import qualified Data.ByteString.Lazy.Char8 as BL
import           Network.AMQP

main :: IO ()
main = do
    withConnection def $ \conn -> do
        chan <- openChannel conn

        --declare queues, exchanges and bindings
        void $ declareQueue chan newQueue {queueName = "myQueueDE"}
        void $ declareQueue chan newQueue {queueName = "myQueueEN"}

        declareExchange chan newExchange {exchangeName = "topicExchg", exchangeType = "topic"}
        bindQueue chan "myQueueDE" "topicExchg" "de.*"
        bindQueue chan "myQueueEN" "topicExchg" "en.*"

        --subscribe to the queues
        void $ consumeMsgs chan "myQueueDE" Ack myCallbackDE
        void $ consumeMsgs chan "myQueueEN" Ack myCallbackEN

        void $ getLine -- wait for keypress
    putStrLn "connection closed"

myCallbackDE :: (Message,Envelope) -> IO ()
myCallbackDE (msg, env) = do
    putStrLn $ "received from DE: "++(BL.unpack $ msgBody msg)
    ackEnv env

myCallbackEN :: (Message,Envelope) -> IO ()
myCallbackEN (msg, env) = do
    putStrLn $ "received from EN: "++(BL.unpack $ msgBody msg)
    ackEnv env
