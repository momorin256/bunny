open Base

type operation = Lowest | Compare | Sum | Product | Prefix | Group

let priority_of_operation = function
  | Lowest -> 0
  | Compare -> 1
  | Sum -> 2
  | Product -> 3
  | Prefix -> 4
  | Group -> 5

let priority_of_token token =
  let infix_op_of_token token =
    let open Token in
    match token with
    | Less | Greater | Equal | NotEqual -> Compare
    | Plus | Minus -> Sum
    | Asterisk -> Product
    | _ -> Lowest
  in
  let op = infix_op_of_token token in
  priority_of_operation op

let rec parse_prefix_int tokens idx =
  match List.nth_exn tokens idx with
  | Token.Integer x -> (Expression.IntLiteral x, idx)
  | _ -> failwith "Expected: Integer"

and parse_prefix_true tokens idx =
  match List.nth_exn tokens idx with
  | Token.True -> (Expression.BoolLiteral true, idx)
  | _ -> failwith "Expected: true"

and parse_prefix_false tokens idx =
  match List.nth_exn tokens idx with
  | Token.False -> (Expression.BoolLiteral false, idx)
  | _ -> failwith "Expected: false"

and parse_prefix_plus tokens idx =
  match List.nth_exn tokens idx with
  | Token.Plus ->
      parse_expr tokens (idx + 1) (priority_of_operation Lowest) (* ingore prefix plus *)
  | _ -> failwith "Expected: Plus"

and parse_prefix_minus tokens idx =
  match List.nth_exn tokens idx with
  | Token.Minus ->
      let expr, last_idx = parse_expr tokens (idx + 1) (priority_of_operation Prefix) in
      (Expression.PrefixExpr (Token.Minus, expr), last_idx)
  | _ -> failwith "Expected: Minus"

and parse_prefix_not tokens idx =
  match List.nth_exn tokens idx with
  | Token.Not ->
      let expr, last_idx = parse_expr tokens (idx + 1) (priority_of_operation Prefix) in
      (Expression.PrefixExpr (Token.Not, expr), last_idx)
  | _ -> failwith "Expected: Not"

and parse_prefix_lparen tokens idx =
  match List.nth_exn tokens idx with
  | Token.Lparen ->
      let expr, last_idx = parse_expr tokens (idx + 1) (priority_of_operation Lowest) in
      (expr, last_idx + 1)
  | _ -> failwith "Expected: Lparen"

(* Get parse prefix function from Token. *)
and get_prefix_fn token =
  match token with
  | Token.Integer _ -> parse_prefix_int
  | Token.Plus -> parse_prefix_plus
  | Token.Minus -> parse_prefix_minus
  | Token.Not -> parse_prefix_not
  | Token.Lparen -> parse_prefix_lparen
  | Token.True -> parse_prefix_true
  | Token.False -> parse_prefix_false
  | _ ->
      failwith (Printf.sprintf "Prefix function is not implemented for %s" (Token.to_string token))

and parse_infix_expr tokens idx left_expr =
  let token = List.nth_exn tokens idx in
  let pri = priority_of_token token in
  let right_expr, last_idx = parse_expr tokens (idx + 1) pri in
  (Expression.InfixExpr (token, left_expr, right_expr), last_idx)

and parse_expr tokens idx pri =
  if List.length tokens <= idx then failwith "Out of bound";

  let get_priority idx =
    if List.length tokens <= idx then priority_of_operation Lowest
    else priority_of_token (List.nth_exn tokens idx)
  in

  let parse_prefix () =
    let prefix_fn = get_prefix_fn (List.nth_exn tokens idx) in
    prefix_fn tokens idx
  in

  let rec loop idx left_expr =
    let next_pri = get_priority (idx + 1) in
    if pri < next_pri then
      let infix_fn = parse_infix_expr in
      let expr, last_idx = infix_fn tokens (idx + 1) left_expr in
      loop last_idx expr
    else (left_expr, idx)
  in

  let left_expr, last_idx = parse_prefix () in
  loop last_idx left_expr

let parse tokens =
  let expr, _ = parse_expr tokens 0 (priority_of_operation Lowest) in
  expr

let parse_string tokens = Expression.to_string (parse tokens)
