module Pos.Core.Ssc.Commitment
       ( Commitment (..)
       , CommitmentSignature
       , SignedCommitment
       , getCommShares
       ) where

import           Universum

import           Control.Lens (each, traverseOf)
import qualified Data.HashMap.Strict as HM

import           Pos.Core.Slotting (EpochIndex)

import           Pos.Binary.Class (AsBinary, fromBinary, serialize')
import           Pos.Crypto (EncShare, PublicKey, SecretProof, Signature, VssPublicKey)

-- | Commitment is a message generated during the first stage of SSC.
-- It contains encrypted shares and proof of secret.
--
-- There can be more than one share generated for a single participant.
data Commitment = Commitment
    { commProof  :: !SecretProof
    , commShares :: !(HashMap (AsBinary VssPublicKey)
                              (NonEmpty (AsBinary EncShare)))
    } deriving (Show, Eq, Generic)

instance NFData Commitment
instance Hashable Commitment

instance Ord Commitment where
    compare = comparing (serialize' . commProof) <>
              comparing (sort . HM.toList . commShares)

-- | Signature which ensures that commitment was generated by node
-- with given public key for given epoch.
type CommitmentSignature = Signature (EpochIndex, Commitment)

type SignedCommitment = (PublicKey, Commitment, CommitmentSignature)

-- | Get commitment shares.
getCommShares :: Commitment -> Maybe [(VssPublicKey, NonEmpty EncShare)]
getCommShares =
    traverseOf (each . _1) (rightToMaybe . fromBinary) <=<      -- decode keys
    traverseOf (each . _2 . each) (rightToMaybe . fromBinary) . -- decode shares
    HM.toList . commShares
