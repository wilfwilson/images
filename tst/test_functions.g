LoadPackage("images", false);
LoadPackage("atlas", false);

##########################################################################
## Minimal Image checking functions
##########################################################################

makeRowColumnSymmetry := function(x,y)
    local perms,i,j,l;
    perms := [];

    for i in [1..(x-1)] do
        l := [1..x*y];
        for j in [1..y] do
            l[i    +(j-1)*x] := (i+1) + (j-1)*x;
            l[(i+1)+(j-1)*x] := i     + (j-1)*x;
        od;
        Append(perms, [PermList(l)]);
    od;

    for j in [1..(y-1)] do
        l := [1..x*y];
        for i in [1..x] do
            l[i+ j*x]    := i + (j-1)*x;
            l[i+(j-1)*x] := i + j*x;
        od;
        Append(perms, [PermList(l)]);
    od;
    return Group(perms);
end;;

randomGroup := function(size)
    if Random([false, true]) then
        return PrimitiveGroup(size, Random([1..NrPrimitiveGroups(size)])) ^ Random(SymmetricGroup(size));
    else
        return TransitiveGroup(size, Random([1..NrTransitiveGroups(size)])) ^ Random(SymmetricGroup(size));
    fi;
end;;


allTinyPrimitiveGroups := function(size)
    return Union(List([1..size], x -> List([1..NrPrimitiveGroups(x)], y -> PrimitiveGroup(x,y))));
end;;

if not IsBound(FERRET_TEST_LIMIT) then
    FERRET_TEST_LIMIT := rec(count := 100, groupSize := 8);
fi;

# We use our own Random Transformation function, to
# get transformations where the result can be > size
cajRandomTransformation := function(size)
    return Transformation([1..size],List([1..size], x -> Random([1..size*2])));
end;;

RandomSet:= function(len)
    return Set([1..Random([0..len])], x -> Random([1..len + 5]));
end;

RandomSetSet := function(len)
    return Set([1..Random([0..len])], x -> RandomSet(Random([0..len+2])));
end;

CheckMinimalImageTest := function(g, o, action, minList)
    local good_min, nostab_min, slow_min, cpyg, rando, can_orig, can_rand, perm_orig, perm_rand, order, gp;
    cpyg := Group(GeneratorsOfGroup(g), ());
    good_min := MinimalImage(g, o, action);
    nostab_min := CanonicalImage(cpyg, o, action, rec(stabilizer := Group(()), result := GetImage));
    slow_min := minList(List(g, p -> action(o,p)));

    if good_min <> slow_min or good_min <> nostab_min then
      Print(GeneratorsOfGroup(g)," ",o, " we found ", [good_min, nostab_min], " right answer is: ", slow_min,"\n");
    fi;

    if (good_min = o) <> IsMinimalImage(g, o, action) then
        Print(GeneratorsOfGroup(g), " ",o, " failure of GetBool\n");
    fi;

    if good_min <> action(o,MinimalImagePerm(g, o, action)) then
        Print(GeneratorsOfGroup(g), " ",o, " failure of GetPerm\n");
    fi;
    
    rando := action(o, Random(g));
    for order in [CanonicalConfig_Fast, CanonicalConfig_MinVal, CanonicalConfig_MinOrbit, CanonicalConfig_MaxOrbit] do
        for gp in [cpyg, Group(())] do
            can_orig := CanonicalImage(cpyg, o, action, rec(stabilizer := Group(()), order := order, result := GetImage));
            can_rand := CanonicalImage(cpyg, rando, action, rec(stabilizer := Group(()), order := order, result := GetImage));
            perm_orig := CanonicalImage(cpyg, o, action, rec(stabilizer := Group(()), order := order, result := GetPerm));
            perm_rand := CanonicalImage(cpyg, rando, action, rec(stabilizer := Group(()), order := order, result := GetPerm));
        od;
        if not(perm_orig in g and perm_rand in g and
               action(o, perm_orig) = can_orig and action(rando, perm_rand) = can_rand and
               can_orig = can_rand) then
            Print(GeneratorsOfGroup(g), ":", order, ":", o, ":", rando, ":", can_orig, ":", can_rand, "\n");
        fi;
    od;

end;;

CheckMinimalImageTransformations := function()
    local i;
    CheckMinimalImageTest(Group(()), Transformation([]), OnPoints, Minimum);
    CheckMinimalImageTest(Group((1,2,3)), Transformation([]), OnPoints, Minimum);
    CheckMinimalImageTest(Group(()), Transformation([1],[6]), OnPoints, Minimum);
    for i in [1..FERRET_TEST_LIMIT.count] do
        CheckMinimalImageTest(randomGroup(Random([2..FERRET_TEST_LIMIT.groupSize])),
                              cajRandomTransformation(Random([1..FERRET_TEST_LIMIT.groupSize + 2])), OnPoints, Minimum);
    od;
end;;

# Wow, hard-wired to only handle up to size 50. How horrible.
# But it's fine for now!
minListPP := function(l)
    local smallest, i;
    smallest := l[1];
    for i in l do
        if AsTransformation(i, 50) < AsTransformation(smallest, 50) then
            smallest := i;
        fi;
    od;
    return smallest;
end;


CheckMinimalImagePartialPerm := function()
    local i;
    CheckMinimalImageTest(Group(()), PartialPerm([]), OnPoints, minListPP);
    CheckMinimalImageTest(Group((1,2,3)), PartialPerm([]), OnPoints, minListPP);
    CheckMinimalImageTest(Group(()), PartialPerm([1],[6]), OnPoints, minListPP);
    for i in [1..FERRET_TEST_LIMIT.count] do
        CheckMinimalImageTest(randomGroup(Random([2..FERRET_TEST_LIMIT.groupSize])),
                              RandomPartialPerm(Random([1..FERRET_TEST_LIMIT.groupSize + 2])), OnPoints, minListPP);
    od;
end;;

CheckMinimalImagePerm := function()
    local i;
    CheckMinimalImageTest(Group(()), PermList([]), OnPoints, Minimum);
    CheckMinimalImageTest(Group((1,2,3)), PermList([]), OnPoints, Minimum);
    CheckMinimalImageTest(Group(()), PermList([3,2,1]), OnPoints, Minimum);
    for i in [1..FERRET_TEST_LIMIT.count] do
        CheckMinimalImageTest(randomGroup(Random([2..FERRET_TEST_LIMIT.groupSize])),
                               Random(SymmetricGroup(Random([1..FERRET_TEST_LIMIT.groupSize + 2]))), OnPoints, Minimum);
    od;
end;;


CheckMinimalImageSet := function()
    local i;
    CheckMinimalImageTest(Group(()), [], OnSets, Minimum);
    CheckMinimalImageTest(Group((1,2,3)), [], OnSets, Minimum);
    CheckMinimalImageTest(Group(()), [1,2,3], OnSets, Minimum);
    for i in [1..FERRET_TEST_LIMIT.count] do
        CheckMinimalImageTest(randomGroup(Random([2..FERRET_TEST_LIMIT.groupSize + 1])),
                              RandomSet(Random([1..FERRET_TEST_LIMIT.groupSize + 2])), OnSets, Minimum);
    od;
end;;

CheckMinimalImageTuple := function()
    local i;
    CheckMinimalImageTest(Group(()), [], OnTuples, Minimum);
    CheckMinimalImageTest(Group((1,2,3)), [], OnTuples, Minimum);
    CheckMinimalImageTest(Group(()), [1,2,3], OnTuples, Minimum);
    for i in [1..FERRET_TEST_LIMIT.count] do
        CheckMinimalImageTest(randomGroup(Random([2..FERRET_TEST_LIMIT.groupSize])),
                              Shuffle(RandomSet(Random([1..FERRET_TEST_LIMIT.groupSize + 2]))), OnTuples, Minimum);
    od;
end;;

CheckMinimalImageTupleTransformation := function()
    local i;
    for i in [1..FERRET_TEST_LIMIT.count] do
        CheckMinimalImageTest(randomGroup(Random([2..FERRET_TEST_LIMIT.groupSize])),
                              List([1..Random([1..FERRET_TEST_LIMIT.groupSize/2])],
                                    x -> cajRandomTransformation(Random([1..FERRET_TEST_LIMIT.groupSize + 2]))), OnTuples, Minimum);
    od;
end;;

CheckMinimalImageSetSet := function()
    local i;
    CheckMinimalImageTest(Group(()), [[]], OnSetsSets, Minimum);
    CheckMinimalImageTest(Group((1,2,3)), [[]], OnSetsSets, Minimum);
    CheckMinimalImageTest(Group(()), [[1,2,3]], OnSetsSets, Minimum);
    for i in [1..FERRET_TEST_LIMIT.count] do
        CheckMinimalImageTest(randomGroup(Random([2..FERRET_TEST_LIMIT.groupSize])),
                              RandomSetSet(Random([1..FERRET_TEST_LIMIT.groupSize + 2])), OnSetsSets, Minimum);
    od;
end;;
