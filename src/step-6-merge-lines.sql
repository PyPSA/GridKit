begin;
drop table if exists line_pairs;
drop table if exists line_sets;
create table line_pairs (
    src text,
    dst text,
    primary key (src, dst)
);

create table line_sets (
    k text,
    v text,
    e geometry(linestring, 3857),
    primary key (v)
);

insert into line_pairs (src, dst)
   select distinct least(a.osm_id, b.osm_id), greatest(a.osm_id, b.osm_id)
       from terminal_intersections i
       join line_terminals a on a.id = i.src
       join line_terminals b on b.id = i.dst;

insert into line_sets (k, v, e) select osm_id, osm_id, extent from power_line;


create index line_sets_k on line_sets (k);
create index line_sets_v on line_sets (v);
-- union-find algorithm again.


drop function if exists connect_lines(a geometry(linestring), b geometry(linestring));
create function connect_lines (a geometry(linestring), b geometry(linestring)) returns geometry(linestring) as $$
begin
    -- select the shortest line that comes from joining the lines
     -- in all possible directions
    return (select e from (
               select unnest(
                   array[st_makeline(a, b),
                         st_makeline(a, st_reverse(b)),
                         st_makeline(st_reverse(a), b),
                         st_makeline(st_reverse(a), st_reverse(b))]) e) f
                   order by st_length(e) limit 1);
end
$$ language plpgsql;
do $$
declare
    s record;
    d record;
    l line_pairs;
begin
    for l in select * from line_pairs loop
        select k, e into s from line_sets where v = l.src;
        select k, e into d from line_sets where v = l.dst;
        if s.k != d.k then
            update line_sets set k = s.k where k = d.k;
            update line_sets set e = connect_lines(s.e, d.e) where k = s.k;
        end if;
     end loop;
end
$$ language plpgsql;

drop table if exists merged_lines;
create table merged_lines (
       synth_id varchar(64),
       extent   geometry(linestring, 3857),
       source text[],
       objects  text[]
);
insert into merged_lines (synth_id, extent, source, objects)
       select concat('m', nextval('synthetic_objects')), s.e,
              array_agg(v), array_agg(distinct (select unnest(l.objects)))
              from line_sets s join power_line l on s.v = l.osm_id
              group by s.k, s.e having count(*) >= 2;

insert into power_line (osm_id, power_name, objects, extent, terminals)
       select synth_id, 'merged', objects, extent, st_buffer(st_union(st_startpoint(extent), st_endpoint(extent)), 100)
              from merged_lines;
delete from power_line where osm_id in (select unnest(source) from merged_lines);
commit;