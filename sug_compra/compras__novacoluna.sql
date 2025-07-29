/* --- TRECHO AJUSTADO (cole no SELECT) ----------------------- */
CASE
    /* 0 – OOS */
    WHEN ( COALESCE(SPPR.SALDO,0) + COALESCE(SP.SALDO,0) + COALESCE(SO.SALDO,0) ) = 0
         THEN '0 - OOS'

    /* 1 – Crítico (< mínimo p/ 7 dias) */
    WHEN ( COALESCE(SPPR.SALDO,0) + COALESCE(SP.SALDO,0) + COALESCE(SO.SALDO,0) )
       <
       (
         /* ---------- PG ---------- */
         CEIL( GREATEST(
                COALESCE(
                    GREATEST(
                        CEIL(
                            CEIL((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3) *
                            CASE
                                WHEN NVL(PG1.QTD,0) > CEIL(((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3)*1.05) THEN 1.05
                                WHEN NVL(PG1.QTD,0) < CEIL(((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3)*0.95) THEN 0.95
                                ELSE 1
                            END
                         ) /30*7
                    ),0),0)
             ) )                         /* fecha o CEIL do PG */
         + /* ---------- OR ---------- */
           COALESCE(
             GREATEST(
                CEIL(
                    CEIL((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3) *
                    CASE
                        WHEN NVL(OR1.QTD,0) > CEIL(((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3)*1.05) THEN 1.05
                        WHEN NVL(OR1.QTD,0) < CEIL(((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3)*0.95) THEN 0.95
                        ELSE 1
                    END
                ) /30*7
             ),0)
         + /* ---------- DG ---------- */
           COALESCE(
             GREATEST(
                CEIL(
                    CEIL((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3) *
                    CASE
                        WHEN NVL(DG1.QTD,0) > CEIL(((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3)*1.05) THEN 1.05
                        WHEN NVL(DG1.QTD,0) < CEIL(((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3)*0.95) THEN 0.95
                        ELSE 1
                    END
                ) /30*7
             ),0)
         + /* ---------- B2B ---------- */
           COALESCE(
             GREATEST(
                CEIL(
                    CEIL((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3) *
                    CASE
                        WHEN NVL(B2B1.QTD,0) > CEIL(((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3)*1.05) THEN 1.05
                        WHEN NVL(B2B1.QTD,0) < CEIL(((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3)*0.95) THEN 0.95
                        ELSE 1
                    END
                ) /30*7
             ),0)
         + /* ---------- FR ---------- */
           COALESCE(
             GREATEST(
                CEIL(
                    CEIL((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3) *
                    CASE
                        WHEN NVL(FR1.QTD,0) > CEIL(((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3)*1.05) THEN 1.05
                        WHEN NVL(FR1.QTD,0) < CEIL(((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3)*0.95) THEN 0.95
                        ELSE 1
                    END
                ) /30*7
             ),0)
       )
       THEN '1 - Crítico'

              -- 2 - Short (abaixo do mínimo de 15 dias)
    WHEN (
        COALESCE(SPPR.SALDO,0) + COALESCE(SP.SALDO,0) + COALESCE(SO.SALDO,0)
    ) <
        (
            /* ---------- PG ---------- */
            CEIL( GREATEST(
                    COALESCE(
                        GREATEST(
                            CEIL(
                                CEIL((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3) *
                                CASE
                                    WHEN NVL(PG1.QTD,0) > CEIL(((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3)*1.05) THEN 1.05
                                    WHEN NVL(PG1.QTD,0) < CEIL(((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3)*0.95) THEN 0.95
                                    ELSE 1
                                END
                            ) /30*15
                        ),0),0 )
            )
            + /* ---------- OR ---------- */
              COALESCE(
                GREATEST(
                    CEIL(
                        CEIL((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3) *
                        CASE
                            WHEN NVL(OR1.QTD,0) > CEIL(((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3)*1.05) THEN 1.05
                            WHEN NVL(OR1.QTD,0) < CEIL(((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3)*0.95) THEN 0.95
                            ELSE 1
                        END
                    ) /30*15
                ),0)
            + /* ---------- DG ---------- */
              COALESCE(
                GREATEST(
                    CEIL(
                        CEIL((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3) *
                        CASE
                            WHEN NVL(DG1.QTD,0) > CEIL(((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3)*1.05) THEN 1.05
                            WHEN NVL(DG1.QTD,0) < CEIL(((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3)*0.95) THEN 0.95
                            ELSE 1
                        END
                    ) /30*15
                ),0)
            + /* ---------- B2B ---------- */
              COALESCE(
                GREATEST(
                    CEIL(
                        CEIL((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3) *
                        CASE
                            WHEN NVL(B2B1.QTD,0) > CEIL(((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3)*1.05) THEN 1.05
                            WHEN NVL(B2B1.QTD,0) < CEIL(((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3)*0.95) THEN 0.95
                            ELSE 1
                        END
                    ) /30*15
                ),0)
            + /* ---------- FR ---------- */
              COALESCE(
                GREATEST(
                    CEIL(
                        CEIL((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3) *
                        CASE
                            WHEN NVL(FR1.QTD,0) > CEIL(((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3)*1.05) THEN 1.05
                            WHEN NVL(FR1.QTD,0) < CEIL(((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3)*0.95) THEN 0.95
                            ELSE 1
                        END
                    ) /30*15
                ),0)
        )
        THEN '2 - Short'

          /* 3 – Ponto de Equilíbrio (entre mínimo 15 e máximo 45 dias) */
WHEN ( COALESCE(SPPR.SALDO,0) + COALESCE(SP.SALDO,0) + COALESCE(SO.SALDO,0) )
     BETWEEN
     /* ---------- LIMITE INFERIOR (15 dias) ---------- */
     (
       /* PG */
       CEIL( GREATEST( COALESCE(
              GREATEST(
                 CEIL(
                   CEIL((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3) *
                   CASE
                     WHEN NVL(PG1.QTD,0) > CEIL(((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3)*1.05) THEN 1.05
                     WHEN NVL(PG1.QTD,0) < CEIL(((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3)*0.95) THEN 0.95
                     ELSE 1
                   END
                 ) /30*15
               ),0),0) )
       /* OR */
       + COALESCE( GREATEST( CEIL(
            CEIL((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3) *
            CASE
              WHEN NVL(OR1.QTD,0) > CEIL(((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3)*1.05) THEN 1.05
              WHEN NVL(OR1.QTD,0) < CEIL(((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3)*0.95) THEN 0.95
              ELSE 1
            END
          ) /30*15 ),0)
       /* DG */
       + COALESCE( GREATEST( CEIL(
            CEIL((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3) *
            CASE
              WHEN NVL(DG1.QTD,0) > CEIL(((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3)*1.05) THEN 1.05
              WHEN NVL(DG1.QTD,0) < CEIL(((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3)*0.95) THEN 0.95
              ELSE 1
            END
          ) /30*15 ),0)
       /* B2B */
       + COALESCE( GREATEST( CEIL(
            CEIL((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3) *
            CASE
              WHEN NVL(B2B1.QTD,0) > CEIL(((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3)*1.05) THEN 1.05
              WHEN NVL(B2B1.QTD,0) < CEIL(((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3)*0.95) THEN 0.95
              ELSE 1
            END
          ) /30*15 ),0)
       /* FR */
       + COALESCE( GREATEST( CEIL(
            CEIL((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3) *
            CASE
              WHEN NVL(FR1.QTD,0) > CEIL(((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3)*1.05) THEN 1.05
              WHEN NVL(FR1.QTD,0) < CEIL(((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3)*0.95) THEN 0.95
              ELSE 1
            END
          ) /30*15 ),0)
     )
     AND
     /* ---------- LIMITE SUPERIOR (45 dias) ---------- */
     (
       /* PG */
       CEIL( GREATEST( COALESCE(
              GREATEST(
                 CEIL(
                   CEIL((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3) *
                   CASE
                     WHEN NVL(PG1.QTD,0) > CEIL(((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3)*1.05) THEN 1.05
                     WHEN NVL(PG1.QTD,0) < CEIL(((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3)*0.95) THEN 0.95
                     ELSE 1
                   END
                 ) /30*45
               ),0),0) )
       /* OR */
       + COALESCE( GREATEST( CEIL(
            CEIL((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3) *
            CASE
              WHEN NVL(OR1.QTD,0) > CEIL(((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3)*1.05) THEN 1.05
              WHEN NVL(OR1.QTD,0) < CEIL(((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3)*0.95) THEN 0.95
              ELSE 1
            END
          ) /30*45 ),0)
       /* DG */
       + COALESCE( GREATEST( CEIL(
            CEIL((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3) *
            CASE
              WHEN NVL(DG1.QTD,0) > CEIL(((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3)*1.05) THEN 1.05
              WHEN NVL(DG1.QTD,0) < CEIL(((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3)*0.95) THEN 0.95
              ELSE 1
            END
          ) /30*45 ),0)
       /* B2B */
       + COALESCE( GREATEST( CEIL(
            CEIL((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3) *
            CASE
              WHEN NVL(B2B1.QTD,0) > CEIL(((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3)*1.05) THEN 1.05
              WHEN NVL(B2B1.QTD,0) < CEIL(((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3)*0.95) THEN 0.95
              ELSE 1
            END
          ) /30*45 ),0)
       /* FR */
       + COALESCE( GREATEST( CEIL(
            CEIL((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3) *
            CASE
              WHEN NVL(FR1.QTD,0) > CEIL(((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3)*1.05) THEN 1.05
              WHEN NVL(FR1.QTD,0) < CEIL(((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3)*0.95) THEN 0.95
              ELSE 1
            END
          ) /30*45 ),0)
     )
     THEN '3 - Ponto de Equilíbrio'

          /* 5 – Excesso (> 45 e ≤ 90 dias) */
WHEN  ( COALESCE(SPPR.SALDO,0) + COALESCE(SP.SALDO,0) + COALESCE(SO.SALDO,0) )   -- saldo total
      >
      /* ---------- LIMITE 45 DIAS ---------- */
      (
        /* PG */
        CEIL( GREATEST(
               COALESCE(
                 GREATEST(
                   CEIL(
                     CEIL((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3) *
                     CASE
                       WHEN NVL(PG1.QTD,0) > CEIL(((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3)*1.05) THEN 1.05
                       WHEN NVL(PG1.QTD,0) < CEIL(((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3)*0.95) THEN 0.95
                       ELSE 1
                     END
                   ) / 30 * 45
                 ),0
               ),0
             ) )                       -- fecha CEIL do PG (45 dias)
        /* OR */
        + COALESCE( GREATEST( CEIL(
              CEIL((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3) *
              CASE
                WHEN NVL(OR1.QTD,0) > CEIL(((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3)*1.05) THEN 1.05
                WHEN NVL(OR1.QTD,0) < CEIL(((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3)*0.95) THEN 0.95
                ELSE 1
              END
            ) / 30 * 45 ),0)
        /* DG */
        + COALESCE( GREATEST( CEIL(
              CEIL((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3) *
              CASE
                WHEN NVL(DG1.QTD,0) > CEIL(((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3)*1.05) THEN 1.05
                WHEN NVL(DG1.QTD,0) < CEIL(((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3)*0.95) THEN 0.95
                ELSE 1
              END
            ) / 30 * 45 ),0)
        /* B2B */
        + COALESCE( GREATEST( CEIL(
              CEIL((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3) *
              CASE
                WHEN NVL(B2B1.QTD,0) > CEIL(((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3)*1.05) THEN 1.05
                WHEN NVL(B2B1.QTD,0) < CEIL(((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3)*0.95) THEN 0.95
                ELSE 1
              END
            ) / 30 * 45 ),0)
        /* FR */
        + COALESCE( GREATEST( CEIL(
              CEIL((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3) *
              CASE
                WHEN NVL(FR1.QTD,0) > CEIL(((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3)*1.05) THEN 1.05
                WHEN NVL(FR1.QTD,0) < CEIL(((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3)*0.95) THEN 0.95
                ELSE 1
              END
            ) / 30 * 45 ),0)
      )
      AND
      /* ---------- LIMITE 90 DIAS ---------- */
      (  /* mesma estrutura, mas *90 ­– idêntica ao bloco 'Over' */
        CEIL( GREATEST(
               COALESCE(
                 GREATEST(
                   CEIL(
                     CEIL((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3) *
                     CASE
                       WHEN NVL(PG1.QTD,0) > CEIL(((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3)*1.05) THEN 1.05
                       WHEN NVL(PG1.QTD,0) < CEIL(((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3)*0.95) THEN 0.95
                       ELSE 1
                     END
                   ) / 30 * 90
                 ),0
               ),0
             ) )  /* PG-90 */
        + COALESCE( GREATEST( CEIL(
              CEIL((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3) *
              CASE
                WHEN NVL(OR1.QTD,0) > CEIL(((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3)*1.05) THEN 1.05
                WHEN NVL(OR1.QTD,0) < CEIL(((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3)*0.95) THEN 0.95
                ELSE 1
              END
            ) / 30 * 90 ),0)
        + COALESCE( GREATEST( CEIL(
              CEIL((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3) *
              CASE
                WHEN NVL(DG1.QTD,0) > CEIL(((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3)*1.05) THEN 1.05
                WHEN NVL(DG1.QTD,0) < CEIL(((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3)*0.95) THEN 0.95
                ELSE 1
              END
            ) / 30 * 90 ),0)
        + COALESCE( GREATEST( CEIL(
              CEIL((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3) *
              CASE
                WHEN NVL(B2B1.QTD,0) > CEIL(((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3)*1.05) THEN 1.05
                WHEN NVL(B2B1.QTD,0) < CEIL(((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3)*0.95) THEN 0.95
                ELSE 1
              END
            ) / 30 * 90 ),0)
        + COALESCE( GREATEST( CEIL(
              CEIL((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3) *
              CASE
                WHEN NVL(FR1.QTD,0) > CEIL(((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3)*1.05) THEN 1.05
                WHEN NVL(FR1.QTD,0) < CEIL(((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3)*0.95) THEN 0.95
                ELSE 1
              END
            ) / 30 * 90 ),0)
      )
THEN '5 - Excesso'


          /* 4 – Over (> 90 dias) */
WHEN ( COALESCE(SPPR.SALDO,0) + COALESCE(SP.SALDO,0) + COALESCE(SO.SALDO,0) )
     >
     (
       /* ---------- PG ---------- */
       CEIL( GREATEST(
               COALESCE(
                 GREATEST(
                   CEIL(
                     CEIL((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3) *
                     CASE
                       WHEN NVL(PG1.QTD,0) > CEIL(((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3)*1.05) THEN 1.05
                       WHEN NVL(PG1.QTD,0) < CEIL(((NVL(PG1.QTD,0)+NVL(PG2.QTD,0)+NVL(PG3.QTD,0))/3)*0.95) THEN 0.95
                       ELSE 1
                     END
                   ) / 30 * 90     -- horizonte de 90 dias
                 ),0),0)
            ) )                    /* fecha CEIL do PG */
       /* ---------- OR ---------- */
       + COALESCE(
           GREATEST(
             CEIL(
               CEIL((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3) *
               CASE
                 WHEN NVL(OR1.QTD,0) > CEIL(((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3)*1.05) THEN 1.05
                 WHEN NVL(OR1.QTD,0) < CEIL(((NVL(OR1.QTD,0)+NVL(OR2.QTD,0)+NVL(OR3.QTD,0))/3)*0.95) THEN 0.95
                 ELSE 1
               END
             ) / 30 * 90
           ),0)
       /* ---------- DG ---------- */
       + COALESCE(
           GREATEST(
             CEIL(
               CEIL((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3) *
               CASE
                 WHEN NVL(DG1.QTD,0) > CEIL(((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3)*1.05) THEN 1.05
                 WHEN NVL(DG1.QTD,0) < CEIL(((NVL(DG1.QTD,0)+NVL(DG2.QTD,0)+NVL(DG3.QTD,0))/3)*0.95) THEN 0.95
                 ELSE 1
               END
             ) / 30 * 90
           ),0)
       /* ---------- B2B ---------- */
       + COALESCE(
           GREATEST(
             CEIL(
               CEIL((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3) *
               CASE
                 WHEN NVL(B2B1.QTD,0) > CEIL(((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3)*1.05) THEN 1.05
                 WHEN NVL(B2B1.QTD,0) < CEIL(((NVL(B2B1.QTD,0)+NVL(B2B2.QTD,0)+NVL(B2B3.QTD,0))/3)*0.95) THEN 0.95
                 ELSE 1
               END
             ) / 30 * 90
           ),0)
       /* ---------- FR ---------- */
       + COALESCE(
           GREATEST(
             CEIL(
               CEIL((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3) *
               CASE
                 WHEN NVL(FR1.QTD,0) > CEIL(((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3)*1.05) THEN 1.05
                 WHEN NVL(FR1.QTD,0) < CEIL(((NVL(FR1.QTD,0)+NVL(FR2.QTD,0)+NVL(FR3.QTD,0))/3)*0.95) THEN 0.95
                 ELSE 1
               END
             ) / 30 * 90
           ),0)
     )
     THEN '4 - Over'
                                  
END AS "Status_Estoque_Novo",
/* ------------------------------------------------------------ */
