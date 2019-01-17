export print_tree

"""
"""
function print_tree(node::TreeNode; indent = 0, indent_size = 10)

        ## Printing top child
        node.isleaf || print_tree(node.child[1], indent = indent+1, indent_size = indent_size)

        ## Current node
        # Top vertical connection for non leaf
        if !node.isleaf
                for i in 1:(indent_size*(indent))
                        print(" ")
                end
                println("|")
        end     
        # Indent and horizontal connection
        for i in 1:(indent_size*indent)
                (i<=(indent_size*(indent-1))+1) ? print(" ") : print("-")
        end
        # Current node label
        println(node.label)
        # Bottom vertical connection for non leaf
        if !node.isleaf
                for i in 1:(indent_size*(indent))
                        print(" ")
                end
                println("|")
        end     

        ## Printing bottom child
        node.isleaf || print_tree(node.child[2], indent = indent+1,  indent_size = indent_size); 

        return nothing
end