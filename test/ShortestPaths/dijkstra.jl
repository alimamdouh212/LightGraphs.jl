    @testset "Dijkstra" begin
        g4 = path_digraph(5)
        d1 = float([0 1 2 3 4; 5 0 6 7 8; 9 10 0 11 12; 13 14 15 0 16; 17 18 19 20 0])
        d2 = sparse(float([0 1 2 3 4; 5 0 6 7 8; 9 10 0 11 12; 13 14 15 0 16; 17 18 19 20 0]))

        for g in testdigraphs(g4)
            y = @inferred(shortest_paths(g, 2, d1, Dijkstra()))
            z = @inferred(shortest_paths(g, 2, d2, Dijkstra()))

            @test y.parents == z.parents == [0, 0, 2, 3, 4]
            @test y.dists == z.dists == [Inf, 0, 6, 17, 33]

            y = @inferred(shortest_paths(g, 2, d1, Dijkstra(all_paths=true)))
            z = @inferred(shortest_paths(g, 2, d2, Dijkstra(all_paths=true)))
            @test z.predecessors[3] == y.predecessors[3] == [2]

            @test @inferred(paths(z)) == paths(y)
            @test @inferred(paths(z))[4] == paths(z, 4) == paths(y, 4) == [2, 3, 4]

            @test shortest_paths(g, 1, d1) isa ShortestPaths.DijkstraResult
        end

        gx = path_graph(5)
        add_edge!(gx, 2, 4)
        d = ones(Int, 5, 5)
        d[2, 3] = 100
        for g in testgraphs(gx)
            z = @inferred(shortest_paths(g, 1, d, Dijkstra()))
            @test z.dists == [0, 1, 3, 2, 3]
            @test z.parents == [0, 1, 4, 2, 4]
        end

        # small function to reconstruct the shortest path; I copied it from somewhere,
        # can't find the original source to give the credits
        # @Beatzekatze on github
        spath(target, dijkstraStruct, source) = target == source ? target : [spath(dijkstraStruct.parents[target], dijkstraStruct, source) target]
        spaths(ds, targets, source) = [spath(i, ds, source) for i in targets]

        G = Graph(4)
        add_edge!(G, 2, 1)
        add_edge!(G, 2, 3)
        add_edge!(G, 1, 4)
        add_edge!(G, 3, 4)
        add_edge!(G, 2, 2)
        w = [0. 3. 0. 1.;
            3. 0. 2. 0.;
            0. 2. 0. 3.;
            1. 0. 3. 0.]

        for g in testgraphs(G)
            ds = @inferred(shortest_paths(g, 2, w, Dijkstra()) )
          # this loop reconstructs the shortest path for vertices 1, 3 and 4
            @test spaths(ds, [1, 3, 4], 2) == Array[[2 1],
                                                [2 3],
                                                [2 1 4]]

        # here a selflink at source is introduced; it should not change the shortest paths
            w[2, 2] = 10.0
            ds = @inferred(shortest_paths(g, 2, w, Dijkstra()))
          # this loop reconstructs the shortest path for vertices 1, 3 and 4
            @test spaths(ds, [1, 3, 4], 2) == Array[[2 1],
                                                [2 3],
                                                [2 1 4]]
        end

        #615
        m = [0 2 2 0 0; 2 0 0 0 3; 2 0 0 1 2;0 0 1 0 1;0 3 2 1 0]
        G = SimpleGraph(5)
        add_edge!(G, 1, 2)
        add_edge!(G, 1, 3)
        add_edge!(G, 2, 5)
        add_edge!(G, 3, 5)
        add_edge!(G, 3, 4)
        add_edge!(G, 4, 5)
        for g in testgraphs(G)
            ds = @inferred(shortest_paths(g, 1, m, Dijkstra(all_paths=true)))
            @test ds.pathcounts   == [1, 1, 1, 1, 2]
            @test ds.predecessors == [[], [1], [1], [3], [3, 4]]
            @test ds.predecessors == [[], [1], [1], [3], [3, 4]]

            dm = @inferred(shortest_paths(g, 1, Dijkstra(all_paths=true, track_vertices=true)))
            @test dm.pathcounts       == [1, 1, 1, 1, 2]
            @test dm.predecessors     == [[], [1], [1], [3], [2, 3]]
            @test dm.closest_vertices == [1, 2, 3, 5, 4]
        end

        G = SimpleGraph(5)
        add_edge!(G, 1, 2)
        add_edge!(G, 1, 3)
        add_edge!(G, 4, 5)
        for g in testgraphs(G)
            dm = @inferred(shortest_paths(g, 1, Dijkstra(all_paths=true, track_vertices=true)))
            @test dm.closest_vertices == [1, 2, 3, 4, 5]
        end

        @testset "maximum distance setting limits paths found" begin
            G = cycle_graph(6)
            add_edge!(G, 1, 3)
            m = float([0 2 2 0 0 1; 2 0 1 0 0 0; 2 1 0 4 0 0; 0 0 4 0 1 0; 0 0 0 1 0 1; 1 0 0 0 1 0])

            for g in testgraphs(G)
                ds = @inferred(shortest_paths(G, 3, m, Dijkstra(maxdist=3)))
                @test ds.dists == [2, 1, 0, Inf, Inf, 3]
            end
        end 
    end
