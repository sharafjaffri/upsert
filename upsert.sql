DROP TABLE temp_rec CASCADE;

CREATE TABLE temp_rec (
    "id" Bigint NOT NULL PRIMARY KEY,
    "val" integer,
    "val_f" integer
);


CREATE OR REPLACE FUNCTION tbl_temp_rec_insert_trigger() RETURNS TRIGGER AS $$
BEGIN
    EXECUTE 'UPDATE part_temp_rec_'|| NEW.id ||'
                sc SET
                val = sc.val + ($1).val
                WHERE (
                sc.id = ($1).id
                AND sc.val_f = ($1).val_f
                )'
    USING NEW;
    EXECUTE 'INSERT INTO part_temp_rec_'|| NEW.id ||'
                        (id,
                        val,
                        val_f)
                        SELECT
                        ($1).id,
                        ($1).val,
                        ($1).val_f
                        WHERE NOT EXISTS
                        (SELECT * FROM part_temp_rec_'|| NEW.id ||' sc
                        WHERE (
                        sc.id = ($1).id
                        AND sc.val_f = ($1).val_f
                        ))'
    USING NEW;
    RETURN NULL;
    EXCEPTION
        WHEN undefined_table THEN
            EXECUTE 'CREATE TABLE IF NOT EXISTS part_temp_rec_'|| NEW.id ||' (CHECK (id='|| NEW.id ||') ) INHERITS (temp_rec)';
            EXECUTE 'CREATE UNIQUE INDEX sh1_id_val_f_'|| NEW.id ||' ON part_temp_rec_'|| NEW.id ||' (id, val_f)';

            EXECUTE 'INSERT INTO part_temp_rec_'|| NEW.id ||'
                        (id,
                        val,
                        val_f)
                        SELECT
                        ($1).id,
                        ($1).val,
                        ($1).val_f'
            USING NEW;
            RETURN NULL;
END
$$
LANGUAGE plpgsql;


CREATE TRIGGER fk_InsertTrigger_temp_rec
BEFORE INSERT ON temp_rec
FOR EACH ROW
EXECUTE PROCEDURE tbl_temp_rec_insert_trigger();


INSERT INTO temp_rec(id, val, val_f) VALUES(1, 1, 1);
INSERT INTO temp_rec(id, val, val_f) VALUES(1, 2, 1);
INSERT INTO temp_rec(id, val, val_f) VALUES(2, 2, 2);
INSERT INTO temp_rec(id, val, val_f) VALUES(2, 2, 2);
INSERT INTO temp_rec(id, val, val_f) VALUES(2, 2, 3);

select * from temp_rec;
select * from part_temp_rec_1;
select * from part_temp_rec_2;
