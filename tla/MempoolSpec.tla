------------------------ MODULE MempoolSpec ---------------------------------

(***************************************************************************)
(* The mempool spec is carving out the problem that the Doris protocol is  *)
(* solving (as to be proven via refinement).  The specification is         *)
(* intended to match Narwhal & Tusk as described by Danezis, Kogias,       *)
(* Spiegelman in their `^\href{https://arxiv.org/abs/2105.11827}{paper.}^' *)
(* Further inspiration is taken from Narwhal's precurser                   *)
(* `^\href{https://arxiv.org/abs/2102.08325}{DAG-rider.}^'                 *)
(*                                                                         *)
(* We shall refer to these papers as [N&T] and [DAG-R], respectively.      *)
(***************************************************************************)

EXTENDS FiniteSets
-----------------------------------------------------------------------------

(***************************************************************************)
(*                               ON QUORUMS                                *)
(***************************************************************************)

(***************************************************************************)
(* We make the usual assumption about Byzantine failures.  That is,        *)
(* preparing for the setting of a partially synchronous network, we have   *)
(*                                                                         *)
(* - a fixed number of nodes                                               *)
(*                                                                         *)
(* - less than one third of which exhibit Byzantine behaviour.             *)
(*                                                                         *)
(* In the typical setting of N = 3f+1 validators,                          *)
(*                                                                         *)
(* - a "quorum" is any set that contains more than two thirds of all       *)
(*   nodes;                                                                *)
(*                                                                         *)
(* - a "weak quorum" is a set of nodes whose intersection with any quorum  *)
(*   is non-empty.                                                         *)
(*                                                                         *)
(* In prose, _validator_ means (possibly Byzantine) validator.             *)
(***************************************************************************)

\* Following Lamport's formalization of 
\* `^\href{https://tinyurl.com/2dyuzs6y}{Paxos}^' and 
\* `^\href{https://tinyurl.com/7punrbs2}{Byzantine Paxos,}^'
\* we consider a more general formalization that
\* even could take care of infinite sets.

CONSTANTS Validator,     \* The set of correct (aka good) validators.
          FakeValidator, \* The set of possibly faulty (aka bad) validators.
          ByzQuorum,
            (***************************************************************)
            (* A Byzantine quorum is set of validators that includes a     *)
            (* quorum of good ones.  In the case that there are 2f+1 good  *)
            (* validators and f bad ones, any set that contains at least   *)
            (* 2f+1 validators is a Byzantine quorum.                      *)
            (***************************************************************)
          WeakQuorum
            (***************************************************************)
            (* A weak quorum is a set of validators that includes at least *)
            (* one good one.  If there are f bad validators, then any set  *)
            (* that contaions f+1 validators is a weak quorum.             *)
            (***************************************************************)

(***************************************************************************)
(*  ByzValidator is the (disjoint) union of real or fake validators        *)
(*  (cf. BQA below.)                                                       *)
(***************************************************************************)
ByzValidator == Validator \cup FakeValidator 

(***************************************************************************)
(* The following assumptions about validators and quorums are used         *)
(* by Lamport in the  safety proof.                                        *)
(***************************************************************************)
ASSUME BQA ==
  \* A validator in ByzValidator is either good or bad.
  /\ Validator \cap FakeValidator = {}                                     
  \* A qourum is a set of (possibly bad) validators.
  /\ \A Q \in ByzQuorum : Q \subseteq ByzValidator                       
  \* Any two quorums have a good validator in common.
  /\ \A Q1, Q2 \in ByzQuorum : Q1 \cap Q2 \cap Validator # {}            
  \* A weak quorum is a set of validators with at least one good validator.
  /\ \A W \in WeakQuorum : /\ W \subseteq ByzValidator                   
                           /\ W \cap Validator # {}                  

(***************************************************************************)
(* Inspired by Lamport's assumption for liveness, we assume BQLA.          *)
(***************************************************************************)
ASSUME BQLA ==
  \* There is a quorum consisting of good validators only.
  /\ \E Q \in ByzQuorum : Q \subseteq Validator
  \* There is a weak quorum consisting of good validators only.
  /\ \E W \in WeakQuorum : W \subseteq Validator


\* end of "ON QUORUMS"

-----------------------------------------------------------------------------

(***************************************************************************)
(*                    WORKER-PRIMARY DISTINCTION                           *)
(***************************************************************************)

(***************************************************************************)
(* One idea of Narwhal and Tusk [N&T] is explicit parallelism via a number *)
(* of workers at each validator.  Each worker of a (correct) validator     *)
(* will have a "mirror" worker at every other validator.                   *)
(*                                                                         *)
(* We use a public parameter, typically a finite set, which serves to      *)
(* index workers such that mirror workers share the same index.  There is  *)
(* no point of using invalid indices by bad validators as these would be   *)
(* ignored.                                                                *)
(***************************************************************************)

\* 'WorkerIndex' is a publicy known finite set of indices. 
CONSTANT WorkerIndex

ASSUME FiniteIndices == IsFiniteSet(WorkerIndex)

\* A specific worker has a worker 'index' is part of a 'val'idator 
Worker == [index : WorkerIndex, val : ByzValidator] 

(***************************************************************************)
(* There is a bijection between ByzValidators and Primaries.  For the sake *)
(* of simplicity, we identify them in the specification.                   *)
(***************************************************************************)

\* Each 'Primary' is identified with its whole validator node
Primary == ByzValidator 

\* end of "WORKER-PRIMARY DISTINCTION"

=============================================================================
